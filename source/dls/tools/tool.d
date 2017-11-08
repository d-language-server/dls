module dls.tools.tool;

package abstract class Tool(C : ToolConfiguration)
{
    protected static C _configuration;

    @property static void configuration(C config)
    {
        _configuration = config;
    }
}

package interface ToolConfiguration
{
}
