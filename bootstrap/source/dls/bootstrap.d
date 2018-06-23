module dls.bootstrap;

import std.file : exists, isFile, mkdirRecurse, remove;
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
private string[] archiveMemberPaths;

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
    import core.time : hours;
    import std.algorithm : min;
    import std.datetime : Clock, SysTime;
    import std.json : JSONException, parseJSON;
    import std.net.curl : get;

    try
    {
        const releases = parseJSON(get(format!apiEndpoint("releases"))).array;

        foreach (release; releases[0 .. min($, 5)])
        {
            const releaseDate = SysTime.fromISOExtString(release["published_at"].str);

            if (Clock.currTime.toUTC() - releaseDate > 1.hours)
            {
                foreach (asset; release["assets"].array)
                {
                    if (asset["name"].str == format(dlsArchiveName, release["tag_name"].str))
                    {
                        downloadUrl = asset["browser_download_url"].str;
                        downloadVersion = release["tag_name"].str;
                        return true;
                    }
                }
            }
        }
    }
    catch (Exception e)
    {
        // The download URL couldn't be retrieved
    }

    return false;
}

void downloadDls(in void function(size_t size) totalSizeCallback = null,
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
            import core.time : msecs;
            import std.datetime.stopwatch : StopWatch;

            static bool started;
            static StopWatch watch;

            if (!started && dlTotal > 0)
            {
                started = true;
                watch.start();

                if (totalSizeCallback !is null)
                {
                    totalSizeCallback(dlTotal);
                }
            }

            if (started && chunkSizeCallback !is null && dlNow > 0
                    && (watch.peek() >= 500.msecs || dlNow == dlTotal))
            {
                watch.reset();
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
        archiveMemberPaths = [];

        foreach (name, member; archive.directory)
        {
            const memberPath = buildNormalizedPath(dlsDir, name);
            write(memberPath, archive.expand(member));
            archiveMemberPaths ~= memberPath;

            version (Posix)
            {
                import core.sys.posix.sys.stat : chmod;
                import std.conv : octal;
                import std.string : toStringz;

                if (name == dlsExecutable)
                {
                    chmod(memberPath.toStringz(), octal!755);
                }
            }
        }
    }
    else
    {
        throw new UpgradeFailedException("Cannot download DLS");
    }
}

void buildDls(in string dlsDir, in string[] additionalArgs = [])
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

    archiveMemberPaths = [buildNormalizedPath(dlsDir, dlsExecutable)];
}

string linkDls()
{
    import std.file : FileException;
    import std.path : baseName;
    import std.string : endsWith;

    string dlsLinkPath;

    foreach (memberPath; archiveMemberPaths)
    {
        if (!isFile(memberPath))
        {
            throw new FileException(format!"%s doesn't exist"(memberPath));
        }

        const linkPath = buildNormalizedPath(dubBinDir, baseName(memberPath));

        mkdirRecurse(dubBinDir);

        if (exists(linkPath))
        {
            remove(linkPath);
        }

        if (memberPath.endsWith(dlsExecutable))
        {
            dlsLinkPath = linkPath;
        }
    }

    version (Windows)
    {
        import std.algorithm : joiner, map;
        import std.conv : to;
        import std.file : FileException;
        import std.format : format;
        import std.process : Config, execute;

        string[] mklinks;

        foreach (memberPath; archiveMemberPaths)
        {
            mklinks ~= format("mklink %s %s", buildNormalizedPath(dubBinDir,
                    baseName(memberPath)), memberPath);
        }

        const mklinkCommand = mklinks.joiner(" & ").to!string;
        const command = [
            "powershell.exe",
            format!"Start-Process -FilePath cmd.exe -ArgumentList '/c %s' -Verb runas"(
                mklinkCommand)
        ];
        const result = execute(command);

        if (result.status != 0)
        {
            throw new FileException("Symlink failed: " ~ result.output);
        }
    }
    else version (Posix)
    {
        import std.file : symlink;

        foreach (memberPath; archiveMemberPaths)
        {
            const linkPath = buildNormalizedPath(dubBinDir, baseName(memberPath));
            symlink(memberPath, linkPath);
        }
    }
    else
    {
        static assert(false, "Platform not suported");
    }

    return dlsLinkPath;
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
