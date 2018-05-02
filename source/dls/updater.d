module dls.updater;

private enum changelogUrl = "https://github.com/LaurentTreguier/dls/blob/master/CHANGELOG.md";
private immutable additionalArgs = [[], ["--force"]];

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
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.file : FileException, exists, remove, thisExePath;
    import std.format : format;
    import std.path : buildNormalizedPath, dirName;
    import std.process : Config, execute;

    auto currentDlsPath = thisExePath();
    auto dub = new Dub(dirName(currentDlsPath));
    dub.loadPackage();
    const currentDls = dub.project.rootPackage;
    Package[] toRemove;

    auto latestDlsPath = currentDlsPath;
    scope (exit)
    {
        Server.send("dls/didUpdatePath", latestDlsPath);
    }

    foreach (dls; dub.packageManager.getPackageIterator("dls"))
    {
        if (dls.version_ < currentDls.version_)
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

    if (latestVersion.isUnknown() || currentDls.version_ >= latestVersion)
    {
        return;
    }

    auto requestParams = new ShowMessageRequestParams(MessageType.info,
            format!"DLS version %s is available"(latestVersion));
    requestParams.actions = [new MessageActionItem("Upgrade")];

    auto id = Server.send("window/showMessageRequest", requestParams);
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
        latestDlsPath = linkDls(pack.path.toString(), executable);
        requestParams.message = format!" DLS updated to %s [%s]"(latestVersion, latestDlsPath);
        requestParams.actions[0].title = "See what's new";
        id = Server.send("window/showMessageRequest", requestParams);
        send(ownerTid(), Util.ThreadMessageData(id,
                Util.ShowMessageRequestType.showChangelog, changelogUrl));
    }
    else
    {
        Server.send("window/showMessage",
                new ShowMessageParams(MessageType.error, "DLS could not be built"));
    }
}
