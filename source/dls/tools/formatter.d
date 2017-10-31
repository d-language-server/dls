module dls.tools.formatter;

import dfmt.config;
import dfmt.editorconfig;
import dfmt.formatter;
import dls.protocol.configuration;
import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.util.document;
import std.algorithm;
import std.outbuffer;
import std.range;

private immutable EOL[FormatterConfiguration.EndOfLine] eolMap;
private immutable BraceStyle[FormatterConfiguration.BraceStyle] braceStyleMap;

shared static this()
{
    eolMap = [FormatterConfiguration.EndOfLine.lf : EOL.lf, FormatterConfiguration.EndOfLine.cr
        : EOL.cr, FormatterConfiguration.EndOfLine.crlf : EOL.crlf];
    braceStyleMap = [FormatterConfiguration.BraceStyle.allman
        : BraceStyle.allman, FormatterConfiguration.BraceStyle.otbs
        : BraceStyle.otbs, FormatterConfiguration.BraceStyle.stroustrup : BraceStyle.stroustrup];
}

class Formatter
{
    private static shared(FormatterConfiguration) _configuration;

    @property static void configuration(shared(FormatterConfiguration) config)
    {
        _configuration = config;
    }

    static auto formatFile(DocumentUri uri, FormattingOptions options)
    {
        const document = Document[uri];
        auto contents = cast(ubyte[]) document.toString();
        auto config = Config();
        auto buffer = new OutBuffer();
        auto range = new Range();

        range.end.line = document.lines.length;
        range.end.character = document.lines[$ - 1].length;

        auto toOptBool(bool b)
        {
            return b ? OptionalBoolean.t : OptionalBoolean.f;
        }

        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.tab_width = config.indent_size;
        config.end_of_line = eolMap[_configuration.endOfLine];
        config.max_line_length = _configuration.maxLineLength;
        config.dfmt_brace_style = braceStyleMap[_configuration.dfmtBraceStyle];
        config.dfmt_soft_max_line_length = _configuration.dfmtSoftMaxLineLength;
        config.dfmt_align_switch_statements = toOptBool(_configuration.dfmtAlignSwitchStatements);
        config.dfmt_outdent_attributes = toOptBool(_configuration.dfmtOutdentAttributes);
        config.dfmt_split_operator_at_line_end = toOptBool(
                _configuration.dfmtSplitOperatorAtLineEnd);
        config.dfmt_space_after_cast = toOptBool(_configuration.dfmtSpaceAfterCast);
        config.dfmt_space_after_keywords = toOptBool(_configuration.dfmtSpaceAfterKeywords);
        // TODO: dfmtSpaceBeforeFunctionParameters is not yet implemented in dfmt
        config.dfmt_selective_import_space = toOptBool(
                _configuration.dfmtSpaceBeforeFunctionParameters);
        config.dfmt_compact_labeled_statements = _configuration.dfmtCompactLabeledStatements
            ? OptionalBoolean.t : OptionalBoolean.f;

        format(uri, contents, buffer, &config);

        return tuple(buffer.toString(), range);
    }
}
