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

    if (!check)
    {
        const dlsDir = thisExePath().dirName.dirName;
        output = (method == Method.download || (method == Method.auto_ && canDownloadDls)) ? downloadDls(
                progress) : buildDls(dlsDir);
        output = linkDls(output);
    }
    else
    {
        output = (method == Method.download ? canDownloadDls : true).to!string;
    }

    stdout.rawWrite(output);

    return 0;
}
