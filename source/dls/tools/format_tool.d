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

module dls.tools.format_tool;

import dfmt.config : BraceStyle, TemplateConstraintStyle;
import dfmt.editorconfig : EOL;
import dls.tools.configuration : Configuration;
import dls.tools.tool : Tool;

private immutable EOL[Configuration.FormatConfiguration.EndOfLine] eolMap;
private immutable BraceStyle[Configuration.FormatConfiguration.BraceStyle] braceStyleMap;
private immutable TemplateConstraintStyle[Configuration.FormatConfiguration.TemplateConstraintStyle] templateConstraintStyleMap;
private immutable configPattern = "dummy.d";

shared static this()
{
    //dfmt off
    eolMap = [
        Configuration.FormatConfiguration.EndOfLine.lf   : EOL.lf,
        Configuration.FormatConfiguration.EndOfLine.cr   : EOL.cr,
        Configuration.FormatConfiguration.EndOfLine.crlf : EOL.crlf
    ];

    braceStyleMap = [
        Configuration.FormatConfiguration.BraceStyle.allman     : BraceStyle.allman,
        Configuration.FormatConfiguration.BraceStyle.otbs       : BraceStyle.otbs,
        Configuration.FormatConfiguration.BraceStyle.stroustrup : BraceStyle.stroustrup
    ];

    templateConstraintStyleMap = [
        Configuration.FormatConfiguration.TemplateConstraintStyle.conditionalNewlineIndent : TemplateConstraintStyle.conditional_newline_indent,
        Configuration.FormatConfiguration.TemplateConstraintStyle.conditionalNewline       : TemplateConstraintStyle.conditional_newline,
        Configuration.FormatConfiguration.TemplateConstraintStyle.alwaysNewline            : TemplateConstraintStyle.always_newline,
        Configuration.FormatConfiguration.TemplateConstraintStyle.alwaysNewlineIndent      : TemplateConstraintStyle.always_newline_indent
    ];
    //dfmt on
}

class FormatTool : Tool
{
    import dfmt.config : Config;
    import dls.protocol.definitions : Position, Range, TextEdit;
    import dls.protocol.interfaces : FormattingOptions;
    import dls.util.uri : Uri;

    private static FormatTool _instance;

    static void initialize()
    {
        _instance = new FormatTool();
    }

    static void shutdown()
    {
        destroy(_instance);
    }

    @property static FormatTool instance()
    {
        return _instance;
    }

    TextEdit[] formatting(const Uri uri, const FormattingOptions options)
    {
        import dfmt.formatter : format;
        import dls.protocol.logger : logger;
        import dls.util.document : Document;
        import std.outbuffer : OutBuffer;

        logger.info("Formatting %s", uri.path);

        const document = Document.get(uri);
        auto contents = cast(ubyte[]) document.toString();
        auto config = getFormatConfig(uri, options);
        auto buffer = new OutBuffer();
        format(uri.path, contents, buffer, &config);
        return diff(uri, buffer.toString());
    }

    TextEdit[] rangeFormatting(const Uri uri, const Range range, const FormattingOptions options)
    {
        import dls.util.document : Document;
        import std.algorithm : filter;
        import std.array : array;

        const document = Document.get(uri);
        document.validatePosition(range.start);
        document.validatePosition(range.end);

        return formatting(uri, options).filter!((edit) {
            return document.byteAtPosition(edit.range.start) < document.byteAtPosition(range.end)
                && document.byteAtPosition(edit.range.end) > document.byteAtPosition(range.start);
        }).array;
    }

    TextEdit[] onTypeFormatting(const Uri uri, const Position position,
            const FormattingOptions options)
    {
        import dls.util.document : Document;
        import std.algorithm : filter;
        import std.array : array;
        import std.string : stripRight;

        const document = Document.get(uri);
        document.validatePosition(position);

        if (position.character != stripRight(document.lines[position.line]).length)
        {
            return [];
        }

        return formatting(uri, options).filter!(edit => edit.range.start.line == position.line
                || edit.range.end.line == position.line).array;
    }

    private Config getFormatConfig(const Uri uri, const FormattingOptions options)
    {
        import dfmt.editorconfig : IndentStyle, OptionalBoolean, getConfigFor;
        import dls.tools.symbol_tool : SymbolTool;

        static OptionalBoolean toOptBool(bool b)
        {
            return b ? OptionalBoolean.t : OptionalBoolean.f;
        }

        auto conf = getConfig(SymbolTool.instance.getWorkspace(uri));
        Config config;
        config.initializeWithDefaults();
        config.pattern = configPattern;
        config.end_of_line = eolMap[conf.format.endOfLine];
        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.tab_width = config.indent_size;
        config.max_line_length = conf.format.maxLineLength;
        config.dfmt_align_switch_statements = toOptBool(conf.format.dfmtAlignSwitchStatements);
        config.dfmt_brace_style = braceStyleMap[conf.format.dfmtBraceStyle];
        config.dfmt_outdent_attributes = toOptBool(conf.format.dfmtOutdentAttributes);
        config.dfmt_soft_max_line_length = conf.format.dfmtSoftMaxLineLength;
        config.dfmt_space_after_cast = toOptBool(conf.format.dfmtSpaceAfterCast);
        config.dfmt_space_after_keywords = toOptBool(conf.format.dfmtSpaceAfterKeywords);
        config.dfmt_space_before_function_parameters = toOptBool(
                conf.format.dfmtSpaceBeforeFunctionParameters);
        config.dfmt_split_operator_at_line_end = toOptBool(conf.format.dfmtSplitOperatorAtLineEnd);
        config.dfmt_selective_import_space = toOptBool(conf.format.dfmtSelectiveImportSpace);
        config.dfmt_compact_labeled_statements = conf.format.dfmtCompactLabeledStatements
            ? OptionalBoolean.t : OptionalBoolean.f;
        config.dfmt_template_constraint_style
            = templateConstraintStyleMap[conf.format.dfmtTemplateConstraintStyle];
        config.dfmt_single_template_constraint_indent = toOptBool(
                conf.format.dfmtSingleTemplateConstraintIndent);

        auto fileConfig = getConfigFor!Config(uri.path);
        fileConfig.pattern = configPattern;
        config.merge(fileConfig, configPattern);
        return config;
    }

    private TextEdit[] diff(const Uri uri, const string after)
    {
        import dls.util.document : Document;
        import std.ascii : isWhite;
        import std.utf : decode;

        const document = Document.get(uri);
        immutable before = document.toString();
        size_t i;
        size_t j;
        TextEdit[] result;

        size_t startIndex;
        size_t stopIndex;
        string text;

        bool pushTextEdit()
        {
            if (startIndex != stopIndex || text.length > 0)
            {
                result ~= new TextEdit(new Range(document.positionAtByte(startIndex),
                        document.positionAtByte(stopIndex)), text);
                return true;
            }

            return false;
        }

        while (i < before.length || j < after.length)
        {
            auto newI = i;
            auto newJ = j;
            dchar beforeChar;
            dchar afterChar;

            if (newI < before.length)
            {
                beforeChar = decode(before, newI);
            }

            if (newJ < after.length)
            {
                afterChar = decode(after, newJ);
            }

            if (i < before.length && j < after.length && beforeChar == afterChar)
            {
                i = newI;
                j = newJ;

                if (pushTextEdit())
                {
                    startIndex = stopIndex;
                    text = "";
                }
            }

            if (startIndex == stopIndex)
            {
                startIndex = i;
                stopIndex = i;
            }

            auto addition = !isWhite(beforeChar) && isWhite(afterChar);
            immutable deletion = isWhite(beforeChar) && !isWhite(afterChar);

            if (!addition && !deletion)
            {
                addition = before.length - i < after.length - j;
            }

            if (addition && j < after.length)
            {
                text ~= after[j .. newJ];
                j = newJ;
            }
            else if (i < before.length)
            {
                stopIndex = newI;
                i = newI;
            }
        }

        pushTextEdit();
        return result;
    }
}
