module dls.tools.tool;

import dls.protocol.configuration;

abstract class Tool
{
    protected static Configuration _configuration;

    @property static void configuration(Configuration configuration)
    {
        _configuration = configuration;
    }
}
