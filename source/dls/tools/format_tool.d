module dls.tools.format_tool;

import dfmt.config : BraceStyle, TemplateConstraintStyle;
import dfmt.editorconfig : EOL;
import dls.tools.configuration : Configuration;
import dls.tools.tool : Tool;

private immutable EOL[Configuration.FormatConfiguration.EndOfLine] eolMap;
private immutable BraceStyle[Configuration.FormatConfiguration.BraceStyle] braceStyleMap;
private immutable TemplateConstraintStyle[Configuration.FormatConfiguration.TemplateConstraintStyle] templateConstraintStyleMap;

static this()
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
    import dls.protocol.interfaces : FormattingOptions;
    import dls.util.uri : Uri;

    auto format(Uri uri, FormattingOptions options)
    {
        import dfmt.config : Config;
        import dfmt.editorconfig : IndentStyle, OptionalBoolean;
        import dfmt.formatter : format;
        import dls.protocol.definitions : Position, Range, TextEdit;
        import dls.util.document : Document;
        import std.outbuffer : OutBuffer;

        const document = Document[uri];
        auto contents = cast(ubyte[]) document.toString();
        auto config = Config();

        auto toOptBool(bool b)
        {
            return b ? OptionalBoolean.t : OptionalBoolean.f;
        }

        config.initializeWithDefaults();
        config.end_of_line = eolMap[_configuration.format.endOfLine];
        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.tab_width = config.indent_size;
        config.max_line_length = _configuration.format.maxLineLength;
        config.dfmt_align_switch_statements = toOptBool(
                _configuration.format.dfmtAlignSwitchStatements);
        config.dfmt_brace_style = braceStyleMap[_configuration.format.dfmtBraceStyle];
        config.dfmt_outdent_attributes = toOptBool(_configuration.format.dfmtOutdentAttributes);
        config.dfmt_soft_max_line_length = _configuration.format.dfmtSoftMaxLineLength;
        config.dfmt_space_after_cast = toOptBool(_configuration.format.dfmtSpaceAfterCast);
        config.dfmt_space_after_keywords = toOptBool(_configuration.format.dfmtSpaceAfterKeywords);
        config.dfmt_space_before_function_parameters = toOptBool(
                _configuration.format.dfmtSpaceBeforeFunctionParameters);
        config.dfmt_split_operator_at_line_end = toOptBool(
                _configuration.format.dfmtSplitOperatorAtLineEnd);
        config.dfmt_selective_import_space = toOptBool(
                _configuration.format.dfmtSelectiveImportSpace);
        config.dfmt_compact_labeled_statements = _configuration.format.dfmtCompactLabeledStatements
            ? OptionalBoolean.t : OptionalBoolean.f;
        config.dfmt_template_constraint_style
            = templateConstraintStyleMap[_configuration.format.dfmtTemplateConstraintStyle];
        config.dfmt_single_template_constraint_indent = toOptBool(
                _configuration.format.dfmtSingleTemplateConstraintIndent);

        auto buffer = new OutBuffer();
        format(uri, contents, buffer, &config);
        auto range = new Range(new Position(0, 0),
                new Position(document.lines.length, document.lines[$ - 1].length));
        return [new TextEdit(range, buffer.toString())];
    }
}
