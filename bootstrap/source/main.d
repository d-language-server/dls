int main()
{
    import dls.bootstrap : makeLink;
    import std.file : thisExePath;
    import std.path : buildNormalizedPath, dirName;
    import std.process : Config, execute;
    import std.stdio : stdout;

    const dlsDir = thisExePath().dirName.dirName;
    auto cmdLine = ["dub", "build", "--build=release"];

    version (Windows)
    {
        const executable = "dls.exe";
        cmdLine ~= ["--arch=x86_mscoff", "--compiler=dmd"];
    }
    else
    {
        const executable = "dls";
    }

    execute(cmdLine, null, Config.suppressConsole, size_t.max, dlsDir);
    stdout.rawWrite(makeLink(dlsDir, executable));

    return 0;
}
