module dls.tools.tool;

import dls.tools.configuration;

abstract class Tool
{
    protected Configuration _configuration;

    @property void configuration(Configuration configuration)
    {
        _configuration = configuration;
    }
}
