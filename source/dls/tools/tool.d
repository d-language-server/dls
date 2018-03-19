module dls.tools.tool;

abstract class Tool
{
    import dls.tools.configuration : Configuration;

    protected Configuration _configuration;

    @property void configuration(Configuration configuration)
    {
        _configuration = configuration;
    }
}
