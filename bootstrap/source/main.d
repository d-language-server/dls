int main()
{
    import dls.bootstrap : buildDls, linkDls;
    import std.file : thisExePath;
    import std.path : dirName;
    import std.stdio : stdout;

    const dlsDir = thisExePath().dirName.dirName;
    stdout.rawWrite(linkDls(dlsDir, buildDls(dlsDir)));

    return 0;
}
