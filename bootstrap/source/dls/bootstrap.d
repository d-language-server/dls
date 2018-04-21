module dls.bootstrap;

auto makeLink(string dlsDir, string executable)
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
        import std.format : format;
        import std.process : Config, executeShell;

        executeShell(format!"MKLINK %s %s"(linkPath, dlsPath), null, Config.suppressConsole);
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
