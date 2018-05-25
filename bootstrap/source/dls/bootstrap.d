module dls.bootstrap;

import std.file : exists, isFile, mkdirRecurse, remove;
import std.format : format;
import std.path : buildNormalizedPath;

immutable repoBase = import("repo.txt");
immutable apiEndpoint = format!"https://api.github.com/repos/%s/dls/releases/latest"(repoBase);

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
    immutable dlsExecutable = "dls.exe";
}
else
{
    immutable dlsExecutable = "dls";
}

private immutable string dlsArchiveName;
private immutable string dlsDirName = "dls-%s";
private string downloadUrl;
private string downloadVersion;

shared static this()
{
    version (X86)
    {
        import core.cpuid : isX86_64;

        arch = isX86_64 ? "x86_64" : "x86";
    }

    dlsArchiveName = format("dls-%%s.%s.%s.zip", os, arch);
}

@property bool canDownloadDls()
{
    import std.json : JSONException, parseJSON;
    import std.net.curl : get;

    try
    {
        const latestRelease = parseJSON(get(apiEndpoint));

        foreach (asset; latestRelease["assets"].array)
        {
            if (asset["name"].str == format(dlsArchiveName, latestRelease["tag_name"].str))
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

string downloadDls(in void function(size_t size) totalSizeCallback = null,
        in void function(size_t size) chunkSizeCallback = null,
        in void function() extractCallback = null)
{
    import std.array : appender;
    import std.net.curl : HTTP;
    import std.file : rmdirRecurse, write;
    import std.zip : ZipArchive;

    if (downloadUrl.length > 0 || canDownloadDls)
    {
        const dlsDir = buildNormalizedPath(dubBinDir, format(dlsDirName, downloadVersion));
        auto request = HTTP(downloadUrl);
        auto archiveData = appender!(ubyte[]);

        if (exists(dlsDir))
        {
            if (isFile(dlsDir))
            {
                remove(dlsDir);
            }
            else
            {
                rmdirRecurse(dlsDir);
            }
        }

        mkdirRecurse(dlsDir);

        request.onReceive = (in ubyte[] data) {
            archiveData ~= data;
            return data.length;
        };

        request.onProgress = (size_t dlTotal, size_t dlNow, size_t ulTotal, size_t ulNow) {
            static bool started;

            if (!started && dlTotal > 0)
            {
                started = true;

                if (totalSizeCallback !is null)
                {
                    totalSizeCallback(dlTotal);
                }
            }

            if (chunkSizeCallback !is null && dlNow > 0)
            {
                chunkSizeCallback(dlNow);
            }

            return 0;
        };

        request.perform();

        if (extractCallback !is null)
        {
            extractCallback();
        }

        auto archive = new ZipArchive(archiveData.data);

        foreach (name, member; archive.directory)
        {
            write(buildNormalizedPath(dlsDir, name), archive.expand(member));
        }

        return buildNormalizedPath(dlsDir, dlsExecutable);
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
    import std.file : FileException;

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
    import std.process : environment;

    version (Windows)
    {
        const dubDirPath = environment["LOCALAPPDATA"];
        const dubDirName = "dub";
    }
    else
    {
        const dubDirPath = environment["HOME"];
        const dubDirName = ".dub";
    }

    return buildNormalizedPath(dubDirPath, dubDirName, "packages", ".bin");
}

class UpgradeFailedException : Exception
{
    this(in string message)
    {
        super(message);
    }
}
