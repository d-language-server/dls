module dls.protocol.configuration;

import dls.tools.code_completer;
import dls.tools.formatter;

class Configuration
{
    CodeCompleterConfiguration codeCompleter;
    FormatterConfiguration formatter;

    static void set(Configuration c)
    {
        CodeCompleter.configuration = c.codeCompleter;
        Formatter.configuration = c.formatter;
    }
}
