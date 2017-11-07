module dls.tools.tool;

import dls.protocol.configuration;

package abstract class Tool(C : ToolConfiguration)
{
    protected static C _configuration;

    @property static void configuration(C config)
    {
        _configuration = config;
    }
}
