module dls.updater;

import dls.bootstrap : repoBase;
import std.format : format;

private enum changelogUrl = format!"https://github.com/%s/dls/blob/master/CHANGELOG.md"(repoBase);
private enum descriptionJson = import("description.json");

enum UpgradeType
{
    pass,
    download,
    build
}

void update()
{
    import dls.bootstrap : UpgradeFailedException, buildDls, canDownloadDls,
        downloadDls, dubBinDir, linkDls, suffix;
    import dls.protocol.interfaces : MessageActionItem, MessageType,
        ShowMessageParams, ShowMessageRequestParams;
    import dls.protocol.messages.window : Util;
    import dls.server : Server;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.package_ : Package;
    import std.regex : matchFirst;
    import std.algorithm : find;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.file : FileException, SpanMode, dirEntries, remove;
    import std.json : parseJSON;
    import std.net.curl : CurlException;
    import std.path : baseName, dirName;

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
        const match = entry.name.baseName.matchFirst(`dls-v([\d.]+)\.` ~ suffix);

        if (match && match[1] < currentVersion)
        {
            try
            {
                remove(entry.name);
            }
            catch (FileException e)
            {
                // No big deal if they can't be removed for some reason
            }
        }
    }

    const latestVersion = dub.getLatestVersion("dls");

    if (latestVersion.isUnknown() || currentVersion >= latestVersion.toString())
    {
        return;
    }

    auto id = Util.sendMessageRequest(Util.ShowMessageRequestType.upgradeDls,
            [latestVersion.toString(), currentVersion], canDownloadDls ? [] : ["download"]);
    const threadName = "updater";
    register(threadName, thisTid());
    send(ownerTid(), Util.ThreadMessageData(id,
            Util.ShowMessageRequestType.upgradeDls, threadName));

    const upgradeType = receiveOnly!UpgradeType();
    string dlsPath;

    if (upgradeType == UpgradeType.pass)
    {
        return;
    }

    final switch (upgradeType)
    {
    case UpgradeType.pass:
        return;

    case UpgradeType.download:
        try
        {
            dlsPath = downloadDls();
        }
        catch (Exception e)
        {
            Util.sendMessage(Util.ShowMessageType.dlsDownloadError);
            return;
        }

        break;

    case UpgradeType.build:
        FetchOptions fetchOpts;
        fetchOpts |= FetchOptions.forceBranchUpgrade;
        const pack = dub.fetch("dls", Dependency(">=0.0.0"),
                dub.defaultPlacementLocation, fetchOpts);

        int i;
        bool success;
        const additionalArgs = [[], ["--force"]];

        do
        {
            try
            {
                dlsPath = buildDls(pack.path.toString(), additionalArgs[i]);
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

        break;
    }

    try
    {
        const latestDlsPath = linkDls(dlsPath);
        id = Util.sendMessageRequest(Util.ShowMessageRequestType.showChangelog,
                [latestVersion.toString(), latestDlsPath]);
        send(ownerTid(), Util.ThreadMessageData(id,
                Util.ShowMessageRequestType.showChangelog, changelogUrl));
    }
    catch (FileException e)
    {
        Util.sendMessage(Util.ShowMessageType.dlsLinkError);
    }
}
