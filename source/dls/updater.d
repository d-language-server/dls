module dls.updater;

import dls.bootstrap : repoBase;
import dls.protocol.interfaces : InitializeParams;
import std.format : format;

private enum descriptionJson = import("description.json");
private immutable changelogUrl = format!"https://github.com/%s/dls/blob/master/CHANGELOG.md"(
        repoBase);

void update(shared(InitializeParams.InitializationOptions) initOptions)
{
    import core.time : hours;
    import dls.bootstrap : UpgradeFailedException, apiEndpoint, buildDls,
        canDownloadDls, downloadDls, dubBinDir, linkDls;
    import dls.protocol.messages.window : Util;
    import dls.server : Server;
    import dls.util.path : normalized;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.package_ : Package;
    import std.algorithm : find;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.datetime : Clock, SysTime;
    import std.experimental.logger : warningf;
    import std.file : FileException, SpanMode, dirEntries, isFile, remove,
        rmdirRecurse;
    import std.json : parseJSON;
    import std.net.curl : get;
    import std.path : baseName;
    import std.regex : matchFirst;

    const desc = parseJSON(descriptionJson);
    const currentVersion = desc["packages"].array.find!(
            p => p["name"] == desc["rootPackage"])[0]["version"].str;
    auto dub = new Dub();
    Package[] toRemove;

    foreach (dls; dub.packageManager.getPackageIterator("dls"))
    {
        if (dls.version_.toString() < currentVersion)
        {
            toRemove ~= dls;
        }
    }

    foreach (dls; toRemove)
    {
        try
        {
            dub.remove(dls);
        }
        catch (FileException e)
        {
            // No big deal if they can't be removed for some reason
        }
    }

    foreach (entry; dirEntries(dubBinDir, SpanMode.shallow))
    {
        const match = entry.name.baseName.matchFirst(`dls-v([\d.]+)\.zip`);

        if (match && match[1] < currentVersion)
        {
            try
            {
                if (isFile(entry.name))
                {
                    remove(entry.name);
                }
                else
                {
                    rmdirRecurse(entry.name);
                }
            }
            catch (FileException e)
            {
                // No big deal if they can't be removed for some reason
            }
        }
    }

    const latestRelease = parseJSON(get(apiEndpoint));
    const latestVersion = latestRelease["tag_name"].str;
    const releaseDate = SysTime.fromISOExtString(latestRelease["published_at"].str);

    if (latestVersion.length == 0 || currentVersion >= latestVersion
            || (Clock.currTime - releaseDate < 1.hours))
    {
        return;
    }

    auto id = Util.sendMessageRequest(Util.ShowMessageRequestType.upgradeDls,
            [latestVersion, currentVersion]);
    const threadName = "updater";
    register(threadName, thisTid());
    send(ownerTid(), Util.ThreadMessageData(id,
            Util.ShowMessageRequestType.upgradeDls, threadName));

    const shouldUpgrade = receiveOnly!bool();
    string dlsPath;

    if (!shouldUpgrade)
    {
        return;
    }

    Server.send("$/dls.upgradeDls.start");

    scope (exit)
    {
        Server.send("$/dls.upgradeDls.stop");
    }

    bool success;

    if (canDownloadDls)
    {
        try
        {
            enum totalSizeCallback = (size_t size) {
                Server.send("$/dls.upgradeDls.totalSize", size);
            };
            enum chunkSizeCallback = (size_t size) {
                Server.send("$/dls.upgradeDls.currentSize", size);
            };
            enum extractCallback = () { Server.send("$/dls.upgradeDls.extract"); };

            dlsPath = downloadDls(initOptions.lspExtensions.upgradeDls
                    ? totalSizeCallback : null, initOptions.lspExtensions.upgradeDls
                    ? chunkSizeCallback : null,
                    initOptions.lspExtensions.upgradeDls ? extractCallback : null);
            success = true;
        }
        catch (Exception e)
        {
            warningf("Could not download DLS: %s", e.message);
        }
    }

    if (!success)
    {
        FetchOptions fetchOpts;
        fetchOpts |= FetchOptions.forceBranchUpgrade;
        const pack = dub.fetch("dls", Dependency(">=0.0.0"),
                dub.defaultPlacementLocation, fetchOpts);

        int i;
        const additionalArgs = [[], ["--force"]];

        do
        {
            try
            {
                dlsPath = buildDls(pack.path.toString().normalized, additionalArgs[i]);
                success = true;
            }
            catch (UpgradeFailedException e)
            {
                ++i;
            }
        }
        while (i < additionalArgs.length && !success);

        if (!success)
        {
            Util.sendMessage(Util.ShowMessageType.dlsBuildError);
            return;
        }
    }

    try
    {
        linkDls(dlsPath);
        id = Util.sendMessageRequest(Util.ShowMessageRequestType.showChangelog, [latestVersion]);
        send(ownerTid(), Util.ThreadMessageData(id,
                Util.ShowMessageRequestType.showChangelog, changelogUrl));
    }
    catch (FileException e)
    {
        Util.sendMessage(Util.ShowMessageType.dlsLinkError);
    }
}
