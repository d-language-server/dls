/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.bootstrap;

import std.json : JSONValue;

immutable apiEndpoint = "https://api.github.com/repos/d-language-server/dls/%s";

version (Windows)
{
    private immutable os = "windows";
}
else version (OSX)
{
    private immutable os = "osx";
}
else version (linux)
{
    private immutable os = "linux";
}
else version (FreeBSD)
{
    private immutable os = "linux";
}
else
{
    private immutable os = "none";
}

version (Windows)
{
    private immutable dlsExecutable = "dls.exe";
}
else
{
    private immutable dlsExecutable = "dls";
}

private immutable string dlsArchiveName;
private immutable string dlsDirName = "dls-%s";
private immutable string dlsLatestDirName = "dls-latest";
private string downloadUrl;
private string downloadVersion;

version (X86_64)
    version = IntelArchitecture;
else version (X86)
    version = IntelArchitecture;

shared static this()
{
    import std.format : format;

    version (IntelArchitecture)
    {
        import core.cpuid : isX86_64;

        version (Posix)
        {
            import std.process : execute;
            import std.string : strip;
            import std.uni : toLower;

            immutable arch = execute("uname").output.strip()
                .toLower() != "freebsd" && isX86_64 ? "x86_64" : "x86";
        }
        else
        {
            immutable arch = isX86_64 ? "x86_64" : "x86";
        }
    }
    else
    {
        immutable arch = "none";
    }

    dlsArchiveName = format("dls-%%s.%s.%s.zip", os, arch);
}

@property JSONValue[] allReleases()
{
    import std.format : format;
    import std.json : parseJSON;
    import std.net.curl : get;

    return parseJSON(get(format!apiEndpoint("releases"))).array;
}

@property bool canDownloadDls()
{
    import core.time : hours;
    import std.algorithm : min;
    import std.datetime : Clock, SysTime;
    import std.format : format;
    import std.json : JSON_TYPE;

    try
    {
        foreach (release; allReleases)
        {
            immutable releaseDate = SysTime.fromISOExtString(release["published_at"].str);

            if (Clock.currTime.toUTC() - releaseDate > 1.hours
                    && release["prerelease"].type == JSON_TYPE.FALSE)
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

void downloadDls(const void function(size_t size) totalSizeCallback = null,
        const void function(size_t size) chunkSizeCallback = null,
        const void function() extractCallback = null)
{
    import std.array : appender;
    import std.net.curl : HTTP;
    import std.file : exists, isFile, mkdirRecurse, remove, rmdirRecurse, write;
    import std.format : format;
    import std.path : buildNormalizedPath;
    import std.zip : ZipArchive;

    if (downloadUrl.length > 0 || canDownloadDls)
    {
        immutable dlsDir = buildNormalizedPath(dubBinDir, format(dlsDirName, downloadVersion));
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

        request.onReceive = (ubyte[] data) {
            archiveData ~= data;
            return data.length;
        };

        request.onProgress = (size_t dlTotal, size_t dlNow, size_t ulTotal, size_t ulNow) {
            import core.time : Duration, msecs;

            static if (__VERSION__ >= 2075L)
            {
                import std.datetime.stopwatch : StopWatch;
            }
            else
            {
                import std.datetime : StopWatch;
            }

            static bool started;
            static bool stopped;
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

            if (started && !stopped && chunkSizeCallback !is null && dlNow > 0
                    && (cast(Duration) watch.peek() >= 500.msecs || dlNow == dlTotal))
            {
                watch.reset();
                chunkSizeCallback(dlNow);

                if (dlNow == dlTotal)
                {
                    stopped = true;
                    watch.stop();
                }
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
            immutable memberPath = buildNormalizedPath(dlsDir, name);
            write(memberPath, archive.expand(member));

            version (Posix)
            {
                import std.process : execute;

                if (name == dlsExecutable)
                {
                    execute(["chmod", "+x", memberPath]);
                }
            }
        }
    }
    else
    {
        throw new UpgradeFailedException("Cannot download DLS");
    }
}

void buildDls(const string dlsDir, const string[] additionalArgs = [])
{
    import core.cpuid : isX86_64;
    import std.path : buildNormalizedPath;
    import std.process : Config, execute;

    auto cmdLine = ["dub", "build", "--build=release"] ~ additionalArgs;

    version (Windows)
    {
        cmdLine ~= ["--compiler=dmd", "--arch=" ~ (isX86_64 ? "x86_64" : "x86_mscoff")];
    }

    immutable result = execute(cmdLine, null, Config.none, size_t.max, dlsDir);

    if (result.status != 0)
    {
        throw new UpgradeFailedException("Build failed: " ~ result.output);
    }
}

string linkDls()
{
    import std.file : exists, isFile, mkdirRecurse, remove;
    import std.format : format;
    import std.path : baseName, buildNormalizedPath;
    import std.string : endsWith;

    mkdirRecurse(dubBinDir);

    immutable dlsDir = buildNormalizedPath(dubBinDir, format(dlsDirName, downloadVersion));
    immutable oldDlsLink = buildNormalizedPath(dubBinDir, dlsExecutable);
    immutable dlsLatestDir = buildNormalizedPath(dubBinDir, dlsLatestDirName);

    if (exists(oldDlsLink) && !exists(dlsLatestDir))
    {
        makeLink(buildNormalizedPath(dlsLatestDir, dlsExecutable), oldDlsLink, false);
    }

    makeLink(dlsDir, dlsLatestDir, true);

    return buildNormalizedPath(dlsLatestDir, dlsExecutable);
}

@property string dubBinDir()
{
    import std.path : buildNormalizedPath;
    import std.process : environment;

    version (Windows)
    {
        immutable dubDirPath = environment["LOCALAPPDATA"];
        immutable dubDirName = "dub";
    }
    else version (Posix)
    {
        immutable dubDirPath = environment["HOME"];
        immutable dubDirName = ".dub";
    }
    else
    {
        static assert(false, "Platform not supported");
    }

    return buildNormalizedPath(dubDirPath, dubDirName, "packages", ".bin");
}

private void makeLink(const string target, const string link, bool directory)
{
    version (Windows)
    {
        import std.array : join;
        import std.file : exists, isFile, remove, rmdir;
        import std.format : format;
        import std.process : execute;

        if (exists(link))
        {
            if (isFile(link))
            {
                remove(link);
            }
            else
            {
                rmdir(link);
            }
        }

        immutable mklinkCommand = format!`mklink %s "%s" "%s"`(directory ? "/J" : "", link, target);
        const powershellArgs = ["Start-Process", "-Wait", "-FilePath", "cmd.exe",
            "-ArgumentList", format!"'/c %s'"(mklinkCommand), "-WindowStyle", "Hidden"] ~ (directory
                ? [] : ["-Verb", "runas"]);
        immutable result = execute(["powershell.exe", powershellArgs.join(' ')]);

        if (result.status != 0)
        {
            throw new UpgradeFailedException("Symlink failed: " ~ result.output);
        }
    }
    else version (Posix)
    {
        import std.file : exists, remove, symlink;

        if (exists(link))
        {
            remove(link);
        }

        symlink(target, link);
    }
    else
    {
        static assert(false, "Platform not supported");
    }
}

class UpgradeFailedException : Exception
{
    this(const string message)
    {
        super(message);
    }
}
