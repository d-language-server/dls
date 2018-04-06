module dls.tools.configuration;

class Configuration
{
    SymbolConfiguration symbol;
    AnalysisConfiguration analysis;
    FormatConfiguration format;

    this()
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
