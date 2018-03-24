int main()
{
    import std.file : thisExePath;
    import std.path : buildNormalizedPath, dirName;
    import std.stdio : stdout;

    stdout.write(thisExePath().dirName.dirName);
    return 0;
}
