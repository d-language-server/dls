module dls.updater;

private enum changelogURL = "https://github.com/LaurentTreguier/dls/blob/master/CHANGELOG.md";
private enum maxTries = 3;

void update()
{
    import dls.protocol.interfaces : MessageActionItem, MessageType,
        ShowMessageParams, ShowMessageRequestParams;
    import dls.protocol.messages.window : Util;
    import dls.server : Server;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.package_ : Package;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.conv : to;
    import std.file : FileException, thisExePath;
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

    auto requestParams = new ShowMessageRequestParams();
    requestParams.type = MessageType.info;
    requestParams.message = format!"DLS version %s is available"(latestVersion);
    requestParams.actions = [new MessageActionItem()];
    requestParams.actions[0].title = "Upgrade";

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
    int status;
    auto cmdLine = ["dub", "build", "--build=release"];

    version (Windows)
    {
        const executable = "dls.exe";
        cmdLine ~= ["--arch=x86_mscoff", "--compiler=dmd"];
    }
    else
    {
        const executable = "dls";
    }

    do
    {
        status = execute(cmdLine, null, Config.suppressConsole, size_t.max, pack.path.toString())
            .status;
        ++i;
    }
    while (i < maxTries && status != 0);

    if (status == 0)
    {
        latestDlsPath = buildNormalizedPath(pack.path.toString(), executable);

        requestParams.message = format!" DLS %s built, and will be used next time."(latestVersion);
        requestParams.actions[0].title = "See what's new";
        id = Server.send("window/showMessageRequest", requestParams);
        send(ownerTid(), Util.ThreadMessageData(id,
                Util.ShowMessageRequestType.showChangelog, changelogURL));
    }
    else
    {
        auto messageParams = new ShowMessageParams();
        messageParams.type = MessageType.error;
        messageParams.message = format!"DLS %s could not be built after %s tries"(
                latestVersion, maxTries);
        Server.send("window/showMessage", messageParams);
    }
}
