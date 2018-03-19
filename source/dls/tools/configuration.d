module dls.tools.configuration;

class Configuration
{
    GeneralConfiguration general = new GeneralConfiguration();
    CodeCompleterConfiguration codeCompleter = new CodeCompleterConfiguration();
    FormatterConfiguration formatter = new FormatterConfiguration();

    static class GeneralConfiguration
    {
        string[] importPaths;
    }

    static class CodeCompleterConfiguration
    {
    }

    static class FormatterConfiguration
    {
        static enum BraceStyle
        {
            allman = "allman",
            otbs = "otbs",
            stroustrup = "stroustrup"
        }

        static enum EndOfLine
        {
            lf = "lf",
            cr = "cr",
            crlf = "crlf"
        }

        EndOfLine endOfLine = EndOfLine.lf;
        int maxLineLength = 120;
        BraceStyle dfmtBraceStyle = BraceStyle.allman;
        int dfmtSoftMaxLineLength = 80;
        bool dfmtAlignSwitchStatements = true;
        bool dfmtOutdentAttributes = true;
        bool dfmtSplitOperatorAtLineEnd = false;
        bool dfmtSpaceAfterCast = true;
        bool dfmtSpaceAfterKeywords = true;
        bool dfmtSpaceBeforeFunctionParameters = false;
        bool dfmtSelectiveImportSpace = true;
        bool dfmtCompactLabeledStatements = true;
    }
}
