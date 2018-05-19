module dls.updater;

private enum changelogUrl = "https://github.com/LaurentTreguier/dls/blob/master/CHANGELOG.md";
private enum descriptionJson = import("description.json");

void update()
{
    import dls.bootstrap : BuildFailedException, buildDls, linkDls;
    import dls.protocol.interfaces : MessageActionItem, MessageType,
        ShowMessageParams, ShowMessageRequestParams;
    import dls.protocol.messages.window : Util;
    import dls.server : Server;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.package_ : Package;
    import std.algorithm : find;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.file : FileException, remove, thisExePath;
    import std.format : format;
    import std.json : parseJSON;
    import std.path : dirName;

    const desc = parseJSON(descriptionJson);
    const currentVersion = desc["packages"].array.find!(
            p => p["name"] == desc["rootPackage"])[0]["version"].str;
    auto dub = new Dub();
    auto latestDlsPath = thisExePath();
    Package[] toRemove;

    scope (exit)
    {
        Server.send("dls/didUpdatePath", latestDlsPath);
    }

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

    const latestVersion = dub.getLatestVersion("dls");

    if (latestVersion.isUnknown() || currentVersion >= latestVersion.toString())
    {
        return;
    }

    auto id = Util.sendMessageRequest(Util.ShowMessageRequestType.upgradeDls,
            [latestVersion.toString(), currentVersion]);
    const threadName = "updater";
    register(threadName, thisTid());
    send(ownerTid(), Util.ThreadMessageData(id,
            Util.ShowMessageRequestType.upgradeDls, threadName));

    const shouldUpgrade = receiveOnly!bool();

    if (!shouldUpgrade)
    {
        return;
    }

    FetchOptions fetchOpts;
    fetchOpts |= FetchOptions.forceBranchUpgrade;
    const pack = dub.fetch("dls", Dependency(">=0.0.0"), dub.defaultPlacementLocation, fetchOpts);

    int i;
    bool success;
    string executable;
    const additionalArgs = [[], ["--force"]];

    do
    {
        try
        {
            executable = buildDls(pack.path.toString(), additionalArgs[i]);
            success = true;
        }
        catch (BuildFailedException e)
        {
            ++i;
        }
    }
    while (i < additionalArgs.length && !success);

    if (success)
    {
        try
        {
            latestDlsPath = linkDls(pack.path.toString(), executable);
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
    else
    {
        Util.sendMessage(Util.ShowMessageType.dlsBuildError);
    }
}
