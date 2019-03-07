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

module dls.tools.format_tool.internal.dfmt_format_tool;

import dls.tools.format_tool.internal.format_tool : FormatTool;

private immutable configPattern = "dummy.d";

class DfmtFormatTool : FormatTool
{
    import dfmt.config : Config;
    import dls.protocol.definitions : Position, Range, TextEdit;
    import dls.protocol.interfaces : FormattingOptions;
    import dls.util.uri : Uri;

    override TextEdit[] formatting(const Uri uri, const FormattingOptions options)
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

    private Config getFormatConfig(const Uri uri, const FormattingOptions options)
    {
        import dfmt.config : BraceStyle, TemplateConstraintStyle;
        import dfmt.editorconfig : EOL, IndentStyle, OptionalBoolean, getConfigFor;
        import dls.tools.configuration : Configuration;
        import dls.tools.symbol_tool : SymbolTool;

        static OptionalBoolean toOptBool(bool b)
        {
            return b ? OptionalBoolean.t : OptionalBoolean.f;
        }

        auto formatConf = getConfig(SymbolTool.instance.getWorkspace(uri)).format;
        Config config;
        config.initializeWithDefaults();
        config.pattern = configPattern;
        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.tab_width = config.indent_size;
        config.max_line_length = formatConf.maxLineLength;
        config.dfmt_align_switch_statements = toOptBool(formatConf.alignSwitchStatements);
        config.dfmt_outdent_attributes = toOptBool(formatConf.outdentAttributes);
        config.dfmt_soft_max_line_length = formatConf.softMaxLineLength;
        config.dfmt_space_after_cast = toOptBool(formatConf.spaceAfterCasts);
        config.dfmt_space_after_keywords = toOptBool(formatConf.spaceAfterKeywords);
        config.dfmt_space_before_function_parameters = toOptBool(
                formatConf.spaceBeforeFunctionParameters);
        config.dfmt_split_operator_at_line_end = toOptBool(formatConf.splitOperatorsAtLineEnd);
        config.dfmt_selective_import_space = toOptBool(formatConf.spaceBeforeSelectiveImportColons);
        config.dfmt_compact_labeled_statements = formatConf.compactLabeledStatements
            ? OptionalBoolean.t : OptionalBoolean.f;
        config.dfmt_single_template_constraint_indent = toOptBool(
                formatConf.templateConstraintsSingleIndent);

        final switch (formatConf.endOfLine)
        {
        case Configuration.FormatConfiguration.EndOfLine.lf:
            config.end_of_line = EOL.lf;
            break;
        case Configuration.FormatConfiguration.EndOfLine.cr:
            config.end_of_line = EOL.cr;
            break;
        case Configuration.FormatConfiguration.EndOfLine.crlf:
            config.end_of_line = EOL.crlf;
            break;
        }

        final switch (formatConf.braceStyle)
        {
        case Configuration.FormatConfiguration.BraceStyle.allman:
            config.dfmt_brace_style = BraceStyle.allman;
            break;
        case Configuration.FormatConfiguration.BraceStyle.otbs:
            config.dfmt_brace_style = BraceStyle.otbs;
            break;
        case Configuration.FormatConfiguration.BraceStyle.stroustrup:
            config.dfmt_brace_style = BraceStyle.stroustrup;
            break;
        }

        final switch (formatConf.templateConstraintsStyle)
        {
        case Configuration.FormatConfiguration.TemplateConstraintsStyle.conditionalNewlineIndent:
            config.dfmt_template_constraint_style
                = TemplateConstraintStyle.conditional_newline_indent;
            break;
        case Configuration.FormatConfiguration.TemplateConstraintsStyle.conditionalNewline:
            config.dfmt_template_constraint_style = TemplateConstraintStyle.conditional_newline;
            break;
        case Configuration.FormatConfiguration.TemplateConstraintsStyle.alwaysNewline:
            config.dfmt_template_constraint_style = TemplateConstraintStyle.always_newline;
            break;
        case Configuration.FormatConfiguration.TemplateConstraintsStyle.alwaysNewlineIndent:
            config.dfmt_template_constraint_style = TemplateConstraintStyle.always_newline_indent;
            break;
        }

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
