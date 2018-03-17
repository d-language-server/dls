module dls.tools.tools;

import dls.tools.code_completer;
import dls.tools.configuration;
import dls.tools.formatter;

final class Tools
{
    static CodeCompleter codeCompleter;
    static Formatter formatter;

    static this()
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
