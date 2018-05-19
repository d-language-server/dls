module dls.bootstrap;

import std.format : format;
import std.path : buildNormalizedPath;

immutable repoBase = import("repo.txt");
immutable apiEndpoint = format!"https://api.github.com/repos/%s/dls/%%s"(repoBase);

version (Windows)
{
    immutable os = "windows";
}
else version (OSX)
{
    immutable os = "osx";
}
else version (linux)
{
    immutable os = "linux";
}
else
{
    immutable os = "none";
}

version (X86_64)
{
    immutable arch = "x86_64";
}
else version (X86)
{
    immutable string arch;
}
else
{
    immutable arch = "none";
}

version (Windows)
{
    immutable suffix = "exe";
    immutable dlsExecutable = "dls.exe";
}
else
{
    immutable suffix = "run";
    immutable dlsExecutable = "dls";
}

private immutable string dlsBinName;
private immutable string dlsBinShortName;
private string downloadUrl;
private string downloadVersion;

shared static this()
{
    version (X86)
    {
        import core.cpuid : isX86_64;

        arch = isX86_64 ? "x86_64" : "x86";
    }

    dlsBinName = format("dls-%%s.%s.%s.%s", os, arch, suffix);
    dlsBinShortName = format("dls-%%s.%s", suffix);
}

@property bool canDownloadDls()
{
    import std.json : JSONException, parseJSON;
    import std.net.curl : get;

    try
    {
        const latestRelease = parseJSON(get(format!apiEndpoint("releases/latest")));

        foreach (asset; latestRelease["assets"].array)
        {
            if (asset["name"].str == format(dlsBinName, latestRelease["name"].str))
            {
                downloadUrl = asset["browser_download_url"].str;
                downloadVersion = latestRelease["name"].str;
                return true;
            }
        }
    }
    catch (Exception e)
    {
        // The download URL couldn't be retrieved
    }

    return false;
}

string downloadDls(bool progress = false)
{
    import std.net.curl : HTTP;
    import std.file : exists, remove;

    if (downloadUrl.length > 0 || canDownloadDls)
    {
        const dlsPath = buildNormalizedPath(dubBinDir, format(dlsBinShortName, downloadVersion));
        auto request = HTTP(downloadUrl);

        if (exists(dlsPath))
        {
            remove(dlsPath);
        }

        request.onReceive = (in ubyte[] data) {
            import std.file : append;

            append(dlsPath, data);
            return data.length;
        };

        if (progress)
        {
            request.onProgress = (size_t dlTotal, size_t dlNow, size_t ulTotal, size_t ulNow) {
                import std.conv : to;
                import std.stdio : stderr;

                static size_t percentage;
                const newPercentage = (dlTotal == 0) ? 0 : (100 * dlNow / dlTotal);

                if (newPercentage > percentage)
                {
                    percentage = newPercentage;
                    stderr.rawWrite(percentage.to!string ~ '\n');
                }

                return 0;
            };
        }

        request.perform();

        return dlsPath;
    }

    throw new UpgradeFailedException("Cannot download DLS");
}

string buildDls(in string dlsDir, in string[] additionalArgs = [])
{
    import std.process : Config, execute;

    auto cmdLine = ["dub", "build", "--build=release"] ~ additionalArgs;

    version (Windows)
    {
        cmdLine ~= ["--compiler=dmd", "--arch=x86_mscoff"];
    }

    const result = execute(cmdLine, null, Config.none, size_t.max, dlsDir);

    if (result.status != 0)
    {
        throw new UpgradeFailedException("Build failed: " ~ result.output);
    }

    return buildNormalizedPath(dlsDir, dlsExecutable);
}

string linkDls(in string dlsPath)
{
    import std.file : FileException, exists, isFile, mkdirRecurse, remove;

    if (!isFile(dlsPath))
    {
        throw new FileException(format!"%s doesn't exist"(dlsPath));
    }

    const linkPath = buildNormalizedPath(dubBinDir, dlsExecutable);

    mkdirRecurse(dubBinDir);

    if (exists(linkPath))
    {
        remove(linkPath);
    }

    version (Windows)
    {
        import std.file : FileException;
        import std.format : format;
        import std.process : Config, executeShell;

        const result = executeShell(format!"MKLINK %s %s"(linkPath, dlsPath));

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

@property string dubBinDir()
{
    import dub.dub : Dub;

    return buildNormalizedPath((new Dub()).packageManager.completeSearchPath[0].toString(), ".bin");
}

class UpgradeFailedException : Exception
{
    this(in string message)
    {
        super(message);
    }
}
