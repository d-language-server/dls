module dls.tools.tools;

final class Tools
{
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.configuration : Configuration;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;

    static SymbolTool symbolTool;
    static AnalysisTool analysisTool;
    static FormatTool formatTool;

    static void initialize()
    {
        symbolTool = new SymbolTool();
        analysisTool = new AnalysisTool();
        formatTool = new FormatTool();
    }

    static void setConfiguration(Configuration c)
    {
        import dls.tools.tool : Tool;

        Tool._configuration = c;
        symbolTool.importDirectories(c.symbol.importPaths);
    }
}
