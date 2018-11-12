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

module dls.tools.internal.format.repair;

import dparse.lexer : Token, StringCache;
import std.container : SList;

class FormatException : Exception
{
    private this(size_t inTokens, size_t outTokens)
    {
        import std.format : format;

        super(format!"More tokens in output (%s) than in input (%s)"(inTokens, outTokens));
    }
}

string repair(in string inputText, in Token[] inputTokens,
        ref StringCache stringCache, ref string outputText)
{
    import dparse.lexer : LexerConfig, StringBehavior, WhitespaceBehavior, byToken;
    import std.algorithm : endsWith;
    import std.array : array;

    auto emptyLines = findEmptyLines(inputText);
    auto outputTokens = byToken(outputText, LexerConfig("",
            StringBehavior.source, WhitespaceBehavior.skip), &stringCache).array;

    if (inputTokens.length < outputTokens.length)
    {
        throw new FormatException(inputTokens.length, outputTokens.length);
    }

    return browseTokens(inputTokens, outputTokens, emptyLines, outputText);
}

private SList!size_t findEmptyLines(in string inputText)
{
    import std.string : splitLines, strip;
    import std.typecons : Yes;

    size_t index;
    SList!size_t result;

    foreach (line; splitLines(inputText, Yes.keepTerminator))
    {
        index += line.length;

        if (strip(line).length == 0)
            result.insertFront(index);
    }

    return result;
}

private string browseTokens(in Token[] inputTokens, in Token[] outputTokens,
        ref SList!size_t emptyLines, ref string outputText)
{
    import dls.tools.internal.format.util : tokenString;
    import dparse.lexer : tok;
    import std.array : insertInPlace;

    static enum TokenInsertion
    {
        afterPrevious,
        beforecurrent
    }

    void insert(size_t numToken, TokenInsertion insertion, in string text)
    {
        static size_t insertOffset;
        size_t pos;

        final switch (insertion)
        {
        case TokenInsertion.afterPrevious:
            const token = outputTokens[numToken <= 0 ? 0 : numToken - 1];
            pos = token.index + tokenString(token).length;
            break;

        case TokenInsertion.beforecurrent:
            const token = outputTokens[numToken];
            pos = token.index;
            break;
        }

        insertInPlace(outputText, pos + insertOffset, text);
        insertOffset += text.length;
    }

    size_t i;
    size_t j;

    while (i < inputTokens.length || j < outputTokens.length)
    {
        if (i >= inputTokens.length)
            --i;

        if (j >= outputTokens.length)
            --j;

        const inputToken = inputTokens[i];
        const outputToken = outputTokens[j];

        ++i;

        if (inputToken == outputToken)
        {
            ++j;
            continue;
        }

        const inputTokenText = tokenString(inputToken);

        switch (inputToken.type)
        {
        case tok!")":
        case tok!",":
            insert(j, TokenInsertion.afterPrevious, inputTokenText);
            break;

        default:
            insert(j, TokenInsertion.beforecurrent, inputTokenText);
            break;
        }
    }

    return outputText;
}
