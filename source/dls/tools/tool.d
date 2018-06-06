module dls.tools.tool;

abstract class Tool
{
    import dls.tools.configuration : Configuration;

    package static Configuration _configuration;

    static this()
    {
        _configuration = new Configuration();
    }
}
