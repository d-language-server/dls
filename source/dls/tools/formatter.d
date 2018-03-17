module dls.tools.formatter;

import dfmt.config;
import dfmt.editorconfig;
import dfmt.formatter;
import dls.protocol.interfaces;
import dls.tools.configuration;
import dls.tools.tool;
import dls.util.document;
import dls.util.uri;
import std.algorithm;
import std.outbuffer;
import std.range;

private immutable EOL[Configuration.FormatterConfiguration.EndOfLine] eolMap;
private immutable BraceStyle[Configuration.FormatterConfiguration.BraceStyle] braceStyleMap;

static this()
{
    eolMap = [Configuration.FormatterConfiguration.EndOfLine.lf : EOL.lf,
        Configuration.FormatterConfiguration.EndOfLine.cr : EOL.cr,
        Configuration.FormatterConfiguration.EndOfLine.crlf : EOL.crlf];
    braceStyleMap = [Configuration.FormatterConfiguration.BraceStyle.allman
        : BraceStyle.allman, Configuration.FormatterConfiguration.BraceStyle.otbs
        : BraceStyle.otbs, Configuration.FormatterConfiguration.BraceStyle.stroustrup
        : BraceStyle.stroustrup];
}

class Formatter : Tool
{
    static auto format(Uri uri, FormattingOptions options)
    {
        const document = Document[uri];
        auto contents = cast(ubyte[]) document.toString();
        auto config = Config();
        auto buffer = new OutBuffer();
        auto result = new TextEdit();

        result.range.end.line = document.lines.length;
        result.range.end.character = document.lines[$ - 1].length;

        auto toOptBool(bool b)
        {
            return b ? OptionalBoolean.t : OptionalBoolean.f;
        }

        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.tab_width = config.indent_size;
        config.end_of_line = eolMap[_configuration.formatter.endOfLine];
        config.max_line_length = _configuration.formatter.maxLineLength;
        config.dfmt_brace_style = braceStyleMap[_configuration.formatter.dfmtBraceStyle];
        config.dfmt_soft_max_line_length = _configuration.formatter.dfmtSoftMaxLineLength;
        config.dfmt_align_switch_statements = toOptBool(
                _configuration.formatter.dfmtAlignSwitchStatements);
        config.dfmt_outdent_attributes = toOptBool(_configuration.formatter.dfmtOutdentAttributes);
        config.dfmt_split_operator_at_line_end = toOptBool(
                _configuration.formatter.dfmtSplitOperatorAtLineEnd);
        config.dfmt_space_after_cast = toOptBool(_configuration.formatter.dfmtSpaceAfterCast);
        config.dfmt_space_after_keywords = toOptBool(
                _configuration.formatter.dfmtSpaceAfterKeywords);
        config.dfmt_space_before_function_parameters = toOptBool(
                _configuration.formatter.dfmtSpaceBeforeFunctionParameters);
        config.dfmt_selective_import_space = toOptBool(
                _configuration.formatter.dfmtSpaceBeforeFunctionParameters);
        config.dfmt_compact_labeled_statements = _configuration.formatter.dfmtCompactLabeledStatements
            ? OptionalBoolean.t : OptionalBoolean.f;

        dfmt.formatter.format(uri, contents, buffer, &config);

        result.newText = buffer.toString();

        return [result];
    }
}
