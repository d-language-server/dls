module dls.protocol.configuration;

import dls.tools.code_completer;
import dls.tools.formatter;
import dls.tools.tool;

class Configuration
{
    GeneralConfiguration general;
    CodeCompleterConfiguration codeCompleter;
    FormatterConfiguration formatter;

    static void set(Configuration c)
    {
        Tool.configuration = c;
    }

    static class GeneralConfiguration
    {
        string[] importPaths;
    }
}
