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
        enum printSize = (size_t size) {
            stderr.rawWrite(size.to!string ~ '\n');
            stderr.flush();
        };
        enum printExtract = () { stderr.rawWrite("extract\n"); stderr.flush(); };

        output = (method == Method.download || (method == Method.auto_ && canDownloadDls)) ? downloadDls(printSize,
                printSize, printExtract) : buildDls(dlsDir);
        output = linkDls(output);
    }
    else
    {
        output = (method == Method.download ? canDownloadDls : true).to!string;
        status = (method != Method.download || canDownloadDls) ? 0 : 1;
    }

    stdout.rawWrite(output);

    return status;
}
