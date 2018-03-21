module dls.tools.tools;

final class Tools
{
    import dls.tools.code_completer : CodeCompleter;
    import dls.tools.configuration : Configuration;
    import dls.tools.formatter : Formatter;

    static CodeCompleter codeCompleter;
    static Formatter formatter;

    static void initialize()
    {
        codeCompleter = new CodeCompleter();
        formatter = new Formatter();
    }

    static void setConfiguration(Configuration c)
    {
        codeCompleter.configuration = c;
        formatter.configuration = c;
    }
}
