private enum Method
{
    auto_ = "auto",
    download = "download",
    build = "build"
}

int main(string[] args)
{
    import dls.bootstrap : canDownloadDls, buildDls, downloadDls, linkDls;
    import std.conv : to;
    import std.file : thisExePath;
    import std.format : format;
    import std.getopt : getopt, defaultGetoptPrinter;
    import std.path : dirName;
    import std.stdio : stderr, stdout;

    Method method;
    bool check;
    bool progress;

    version (Windows)
    {
        import std.algorithm : splitter;
        import std.file : exists;
        import std.path : buildNormalizedPath;
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

    try
    {
        //dfmt off
        auto info = getopt(args,
                "method|m",
                format!"%s|%s|%s The bootstrapping method."(cast(string) Method.auto_, Method.download, Method.build)
                ~ format!"`%s` tries `%s` and falls back to `%s` if unavailable)."
                    (cast(string) Method.auto_, Method.download, Method.build)
                ~ format!" [default = %s]"(cast(string) method),
                &method,
                "check|c",
                "Checks if the selected method is available."
                ~ format!" [default = %s]"(check),
                &check,
                "progress|p",
                format!"Show progress (for %s method only)."(Method.download)
                ~ format!" [default = %s]"(progress),
                &progress);
        //dfmt on

        if (info.helpWanted)
        {
            defaultGetoptPrinter("DLS bootstrap utility", info.options);
            return 0;
        }
    }
    catch (Exception e)
    {
        stderr.writeln(e.message);
        return 1;
    }

    string output;
    int status;

    if (!check)
    {
        const dlsDir = thisExePath().dirName.dirName;
        const printSize = progress ? (size_t size) {
            stderr.rawWrite(size.to!string ~ '\n');
            stderr.flush();
        } : null;
        const printExtract = progress ? () {
            stderr.rawWrite("extract\n");
            stderr.flush();
        } : null;

        (method == Method.download || (method == Method.auto_ && canDownloadDls)) ? downloadDls(printSize,
                printSize, printExtract) : buildDls(dlsDir);
        output = linkDls();
    }
    else
    {
        const canDownload = canDownloadDls;
        output = (method == Method.download ? canDownload : true).to!string;
        status = (method != Method.download || canDownload) ? 0 : 1;
    }

    stdout.rawWrite(output);

    return status;
}
