module dls.tools.tool;

import dls.tools.configuration;

abstract class Tool
{
    protected static Configuration _configuration;

    @property static void configuration(Configuration configuration)
    {
        _configuration = configuration;
    }
}
