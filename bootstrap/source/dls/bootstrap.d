module dls.bootstrap;

auto buildDls(const(string) dlsDir, const(string[]) additionalArgs = [])
{
    import std.process : Config, execute;

    auto cmdLine = ["dub", "build", "--build=release"] ~ additionalArgs;

    version (Windows)
    {
        const executable = "dls.exe";
        cmdLine ~= ["--compiler=dmd", "--arch=x86_mscoff"];
    }
    else
    {
        const executable = "dls";
    }

    auto result = execute(cmdLine, null, Config.suppressConsole, size_t.max, dlsDir);

    if (result.status != 0)
    {
        throw new BuildFailedException("Build failed: " ~ result.output);
    }

    return executable;
}

auto linkDls(const(string) dlsDir, const(string) executable)
{
    import dub.dub : Dub;
    import std.file : exists, mkdirRecurse, remove;
    import std.path : buildNormalizedPath;

    const dub = new Dub();
    const dubPath = dub.packageManager.completeSearchPath[0].toString();
    const binDir = buildNormalizedPath(dubPath, ".bin");
    const dlsPath = buildNormalizedPath(dlsDir, executable);
    const linkPath = buildNormalizedPath(binDir, executable);

    mkdirRecurse(binDir);

    if (exists(linkPath))
    {
        remove(linkPath);
    }

    version (Windows)
    {
        import std.file : FileException;
        import std.format : format;
        import std.process : Config, executeShell;

        const result = executeShell(format!"MKLINK %s %s"(linkPath, dlsPath),
                null, Config.suppressConsole);

        if (result.status != 0)
        {
            throw new FileException("Symlink failed: " ~ result.output);
        }
    }
    else version (Posix)
    {
        import std.file : symlink;

        symlink(dlsPath, linkPath);
    }
    else
    {
        static assert(false, "Platform not suported");
    }

    return linkPath;
}

class BuildFailedException : Exception
{
    this(string message)
    {
        super(message);
    }
}
