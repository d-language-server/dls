module dls.tools.tool;

abstract class Tool
{
    import dls.tools.configuration : Configuration;

    protected Configuration _configuration = new Configuration();

    @property void configuration(Configuration configuration)
    {
        _configuration = configuration;
    }
}
