module dls.util.setup;

void initialSetup()
{
    version (Windows)
    {
        import std.algorithm : splitter;
        import std.file : exists;
        import std.path : buildNormalizedPath, dirName;
        import std.process : environment;

        version (X86_64)
        {
            enum binDir = "bin64";
        }
        else version (X86)
        {
            enum binDir = "bin";
        }

        foreach (path; splitter(environment["PATH"], ';'))
        {
            if (buildNormalizedPath(path, "dmd.exe").exists())
            {
                environment["PATH"] = buildNormalizedPath(dirName(path), binDir)
                    ~ ';' ~ environment["PATH"];
            }
        }
    }
}
