/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.tools.format_tool.internal.indent_format_tool;

import dls.protocol.definitions : Range;
import dls.tools.format_tool.internal.format_tool : FormatTool;

class IndentFormatTool : FormatTool
{
    import dls.protocol.definitions : Position, TextEdit;
    import dls.protocol.interfaces : FormattingOptions;
    import dls.tools.format_tool.internal.indent_visitor : IndentVisitor;
    import dls.util.uri : Uri;
    import dparse.lexer : Token;

    override TextEdit[] formatting(const Uri uri, const FormattingOptions options)
    {
        import dls.util.document : Document;

        const document = Document.get(uri);
        return rangeFormatting(uri, new Range(new Position(0, 0),
                new Position(document.lines.length, document.lines[$ - 1].length)), options);
    }

    override TextEdit[] rangeFormatting(const Uri uri, const Range range,
            const FormattingOptions options)
    {
        import dls.protocol.logger : logger;
        import dls.tools.format_tool.internal.format_tool : isValidEditFor;
        import dls.util.document : Document;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            WhitespaceBehavior, byToken, getTokensForParser, isStringLiteral, tok;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import std.algorithm : all, canFind, count, filter, fold, map, sort;
        import std.array : appender, array;
        import std.ascii : isWhite;
        import std.range : chain, repeat;
        import std.utf : toUTF8;

        logger.info("Indenting %s", uri.path);

        const document = Document.get(uri);
        document.validatePosition(range.start);

        auto result = appender!(TextEdit[]);
        const data = document.toString();
        auto config = LexerConfig(uri.path, StringBehavior.source, WhitespaceBehavior.include);
        auto stringCache = StringCache(StringCache.defaultBucketCount);
        const tokens = getTokensForParser(data, config, &stringCache);
        auto multilineTokens = byToken(data, config, &stringCache).filter!(
                t => t.type == tok!"comment" || isStringLiteral(t.type));
        RollbackAllocator rollbackAllocator;
        auto visitor = new IndentVisitor(tokens);
        visitor.visit(parseModule(tokens, uri.path, &rollbackAllocator));

        size_t[] outdents;
        auto indentSpans = getIndentLines(tokens, visitor.weakIndentSpans, outdents);
        auto indentBegins = sort(chain(visitor.indentSpans.keys, indentSpans.keys
                .map!(b => repeat(b, indentSpans[b].length).array)
                .fold!q{a ~ b}(cast(size_t[])[])));
        auto indentEnds = sort(chain(visitor.indentSpans.values,
                indentSpans.values.fold!q{a ~ b}(cast(size_t[])[])));
        size_t indents;

        foreach (line, docLine; document.lines)
        {
            while (!indentEnds.empty && indentEnds.front == line + 1)
            {
                --indents;
                indentEnds.popFront();
            }

            auto shouldIndent = true;

            while (!multilineTokens.empty && line >= multilineTokens.front.line)
            {
                immutable text = multilineTokens.front.text;
                immutable commentEndLine = multilineTokens.front.line + text.count(
                        '\r') + text.count('\n') - text.count("\r\n");

                if (line < commentEndLine)
                {
                    shouldIndent = false;
                    break;
                }
                else
                {
                    multilineTokens.popFront();
                }
            }

            shouldIndent &= !docLine.all!isWhite;
            auto indentRange = getIndentRange(docLine);
            indentRange.start.line = indentRange.end.line = line;

            if (shouldIndent && indentRange.isValidEditFor(range))
            {
                auto edit = new TextEdit(indentRange);
                auto actualIndents = indents;

                if (actualIndents > 0 && outdents.canFind(line + 1))
                {
                    --actualIndents;
                }

                auto newText = new wchar[options.insertSpaces
                    ? actualIndents * options.tabSize : actualIndents];
                newText[] = options.insertSpaces ? ' ' : '\t';

                if (newText != docLine[0 .. indentRange.end.character])
                {
                    edit.newText = newText.toUTF8();
                    result ~= edit;
                }
            }

            while (!indentBegins.empty && indentBegins.front == line + 1)
            {
                ++indents;
                indentBegins.popFront();
            }

            auto trailingWhitespaceRange = getTrailingWhitespaceRange(docLine);
            trailingWhitespaceRange.start.line = trailingWhitespaceRange.end.line = line;

            if (trailingWhitespaceRange.end.character - trailingWhitespaceRange.start.character > 0
                    && trailingWhitespaceRange.isValidEditFor(range))
            {
                result ~= new TextEdit(trailingWhitespaceRange, "");
            }
        }

        result ~= getSpacingEdits(uri, range, tokens, visitor);
        return result.data;
    }

    override TextEdit[] onTypeFormatting(const Uri uri, const Position position,
            const FormattingOptions options)
    {
        import dls.util.document : Document;
        import std.string : stripRight;

        const document = Document.get(uri);
        document.validatePosition(position);
        const line = document.lines[position.line];

        if (position.character != stripRight(line).length)
        {
            return [];
        }

        return rangeFormatting(uri, new Range(new Position(position.line, 0),
                new Position(position.line, line.length)), options);
    }

    private size_t[][size_t] getIndentLines(const Token[] tokens,
            const size_t[size_t] weakIndentSpans, ref size_t[] outdents)
    {
        import dparse.lexer : tok;
        import std.algorithm : remove;
        import std.container : SList;

        SList!size_t indentPairBegins;
        size_t[][size_t] indentSpans;
        bool[][size_t] notFirsts;
        size_t currentLine;

        foreach (ref token; tokens)
        {
            switch (token.type)
            {
            case tok!"{", tok!"(", tok!"[":
                indentPairBegins.insertFront(token.line);
                break;

            case tok!"}", tok!")", tok!"]":
                if (indentPairBegins.empty)
                {
                    break;
                }

                if (token.line != indentPairBegins.front)
                {
                    immutable isNotFirst = token.line == currentLine;
                    indentSpans.require(indentPairBegins.front, [token.line]);
                    notFirsts.require(indentPairBegins.front, [isNotFirst]);

                    if (token.line > indentSpans[indentPairBegins.front][$ - 1])
                    {
                        indentSpans[indentPairBegins.front] ~= token.line;
                        notFirsts[indentPairBegins.front] ~= isNotFirst;
                    }
                }

                indentPairBegins.removeFront();
                break;

            case tok!"case", tok!"default":
                if (token.line > currentLine)
                {
                    outdents ~= token.line;
                }

                break;

            default:
                break;
            }

            if (token.line > currentLine)
            {
                currentLine = token.line;
            }
        }

        foreach (begin, end; weakIndentSpans)
        {
            indentSpans.require(begin, [end]);

            if (end > indentSpans[begin][$ - 1] + 1)
            {
                indentSpans[begin] ~= end;
            }
        }

        foreach (begin, ends; notFirsts)
        {
            foreach (i, end; ends)
            {
                if (end)
                {
                    ++indentSpans[begin][i];
                }
            }
        }

        return indentSpans;
    }

    private TextEdit[] getSpacingEdits(const Uri uri, const Range range,
            const Token[] tokens, IndentVisitor visitor)
    {
        import dls.util.document : Document, minusOne;
        import dparse.lexer : tok;
        import std.algorithm : sort;
        import std.array : appender;
        import std.utf : codeLength, toUTF8;

        const document = Document.get(uri);
        auto sortedUnaryOperators = sort(visitor.unaryOperatorIndexes);
        auto sortedGluedColons = sort(visitor.gluedColonIndexes);
        auto result = appender!(TextEdit[]);

        static enum Spacing
        {
            keep,
            empty,
            space
        }

        static size_t tokenLength(const ref Token token)
        {
            import dparse.lexer : str;

            return token.text.length > 0 ? token.text.length : str(token.type).length;
        }

        void pushEdit(Range editRange, const wstring docLine, Spacing spacing)
        {
            import dls.tools.format_tool.internal.format_tool : isValidEditFor;
            import std.utf : toUTF8;

            auto text = spacing == Spacing.empty ? ""w : " "w;

            if (editRange.isValidEditFor(range)
                    && docLine[editRange.start.character .. editRange.end.character] != text)
            {
                result ~= new TextEdit(editRange, text.toUTF8());
            }
        }

        loop: foreach (i, ref token; tokens)
        {
            auto left = Spacing.keep;
            auto right = Spacing.keep;
            Token previous;
            Token next;

            if (i > 0)
            {
                previous = tokens[i - 1];
            }

            if (i + 1 < tokens.length)
            {
                next = tokens[i + 1];
            }

            switch (token.type)
            {
            case tok!"++":
            case tok!"--":
            case tok!"+":
            case tok!"-":
            case tok!"*":
            case tok!"/":
            case tok!"%":
            case tok!"^^":
            case tok!"!":
            case tok!"~":
            case tok!"&":
            case tok!"|":
            case tok!"^":
            case tok!"&&":
            case tok!"||":
            case tok!"=":
            case tok!"+=":
            case tok!"-=":
            case tok!"*=":
            case tok!"/=":
            case tok!"%=":
            case tok!"^^=":
            case tok!"!=":
            case tok!"~=":
            case tok!"&=":
            case tok!"|=":
            case tok!"^=":
            case tok!"==":
            case tok!"<":
            case tok!">":
            case tok!"<<":
            case tok!">>":
            case tok!">>>":
            case tok!"<=":
            case tok!">=":
            case tok!"<<=":
            case tok!">>=":
            case tok!">>>=":
            case tok!"<>=":
            case tok!"!<":
            case tok!"!>":
            case tok!"!<=":
            case tok!"!>=":
            case tok!"!<>":
            case tok!"!<>=":
            case tok!"=>":
            case tok!"?":
            case tok!"..":
                if (sortedUnaryOperators.empty || token.index != sortedUnaryOperators.front)
                {
                    left = Spacing.space;
                    right = Spacing.space;
                }
                else
                {
                    right = Spacing.empty;
                }

                if (!sortedUnaryOperators.empty && token.index >= sortedUnaryOperators.front)
                {
                    sortedUnaryOperators.popFront();
                }

                break;
            case tok!":":
                left = (sortedGluedColons.empty || token.index != sortedGluedColons.front) ? Spacing.space
                    : Spacing.empty;
                right = Spacing.space;

                if (!sortedGluedColons.empty && token.index >= sortedGluedColons.front)
                {
                    sortedGluedColons.popFront();
                }

                break;
            case tok!",":
            case tok!";":
                left = Spacing.empty;
                right = Spacing.space;
                break;
            case tok!"...":
                left = Spacing.empty;
                break;
            case tok!".":
                left = Spacing.empty;
                right = Spacing.empty;
                break;
            default:
                continue loop;
            }

            immutable line = minusOne(token.line);
            const docLine = document.lines[line];
            immutable docLineStr = docLine.toUTF8();

            if (left != Spacing.keep && previous.type != tok!"" && previous.line == token.line)
            {
                immutable startCharacter = codeLength!wchar(
                        docLineStr[0 .. minusOne(previous.column) + tokenLength(previous)]);
                immutable endCharacter = codeLength!wchar(docLineStr[0 .. minusOne(token.column)]);
                auto editRange = new Range(new Position(line, startCharacter),
                        new Position(line, endCharacter));
                pushEdit(editRange, docLine, left);
            }

            if (right != Spacing.keep && next.type != tok!"" && next.line == token.line)
            {
                immutable startCharacter = codeLength!wchar(
                        docLineStr[0 .. minusOne(token.column) + tokenLength(token)]);
                immutable endCharacter = codeLength!wchar(docLineStr[0 .. minusOne(next.column)]);
                auto editRange = new Range(new Position(line, startCharacter),
                        new Position(line, endCharacter));
                pushEdit(editRange, docLine, right);
            }
        }

        return result.data;
    }
}

private Range getIndentRange(const wstring line)
{
    import std.ascii : isWhite;
    import std.string : stripRight;

    auto result = new Range();
    immutable cleanLine = stripRight(line);

    while (result.end.character < cleanLine.length && isWhite(cleanLine[result.end.character]))
    {
        ++result.end.character;
    }

    return result;
}

private Range getTrailingWhitespaceRange(const wstring line)
{
    import std.algorithm : among;
    import std.ascii : isWhite;

    auto result = new Range();
    result.start.character = result.end.character = line.length;

    while (result.start.character > 0 && isWhite(line[result.start.character - 1]))
    {
        --result.start.character;

        if (line[result.start.character].among('\r', '\n'))
        {
            --result.end.character;
        }
    }

    return result;
}
