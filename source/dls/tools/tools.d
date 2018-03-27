module dls.tools.tools;

final class Tools
{
    import dls.tools.configuration : Configuration;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;

    static SymbolTool symbolTool;
    static FormatTool formatTool;

    static void initialize()
    {
        symbolTool = new SymbolTool();
        formatTool = new FormatTool();
    }

    static void setConfiguration(Configuration c)
    {
        symbolTool.configuration = c;
        formatTool.configuration = c;
    }
}
