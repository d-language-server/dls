module dls.util.path;

@safe @property string normalized(in string path)
{
    version (Windows)
    {
        import std.algorithm : startsWith;

        if (path.startsWith('/') || path.startsWith(`\`))
        {
            return path[1 .. $];
        }
    }

    return path;
}
