module dls.tools.configuration;

class Configuration
{
    SymbolConfiguration symbol;
    AnalysisConfiguration analysis;
    FormatConfiguration format;

    @safe this()
    {
        symbol = new SymbolConfiguration();
        analysis = new AnalysisConfiguration();
        format = new FormatConfiguration();
    }

    static class SymbolConfiguration
    {
        string[] importPaths;
    }

    static class AnalysisConfiguration
    {
        string configFile = "dscanner.ini";
    }

    static class FormatConfiguration
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

        static enum TemplateConstraintStyle
        {
            conditionalNewlineIndent = "conditionalNewlineIndent",
            conditionalNewline = "conditionalNewline",
            alwaysNewline = "alwaysNewline",
            alwaysNewlineIndent = "alwaysNewlineIndent"
        }

        EndOfLine endOfLine = EndOfLine.lf;
        int maxLineLength = 120;
        bool dfmtAlignSwitchStatements = true;
        BraceStyle dfmtBraceStyle = BraceStyle.allman;
        bool dfmtOutdentAttributes = true;
        int dfmtSoftMaxLineLength = 80;
        bool dfmtSpaceAfterCast = true;
        bool dfmtSpaceAfterKeywords = true;
        bool dfmtSpaceBeforeFunctionParameters = false;
        bool dfmtSplitOperatorAtLineEnd = false;
        bool dfmtSelectiveImportSpace = true;
        bool dfmtCompactLabeledStatements = true;
        TemplateConstraintStyle dfmtTemplateConstraintStyle = TemplateConstraintStyle
            .conditionalNewlineIndent;
        bool dfmtSingleTemplateConstraintIndent = false;
    }
}
