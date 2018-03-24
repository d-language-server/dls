module dls.updater;

void update()
{
    import dls.protocol.interfaces : MessageActionItem, MessageType,
        ShowMessageParams, ShowMessageRequestParams;
    import dls.protocol.messages : Util;
    import dls.server : Server;
    import dub.compilers.buildsettings : BuildSettings;
    import dub.compilers.compiler : getCompiler;
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.generators.generator : GeneratorSettings;
    import dub.package_ : Package;
    import std.concurrency : ownerTid, receiveOnly, register, send, thisTid;
    import std.file : thisExePath;
    import std.path : buildNormalizedPath, dirName;

    auto currentDlsPath = dirName(thisExePath());
    auto dub = new Dub(currentDlsPath);
    dub.loadPackage();
    const currentDls = dub.project.rootPackage;
    Package[] toRemove;

    auto latestDlsPath = currentDlsPath;
    scope (exit)
    {
        Server.send("telemetry/event", latestDlsPath);
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
        dub.remove(dls);
    }

    const latestVersion = dub.getLatestVersion("dls");

    if (latestVersion.isUnknown() || currentDls.version_ == latestVersion)
    {
        return;
    }

    auto requestParams = new ShowMessageRequestParams();
    requestParams.type = MessageType.info;
    requestParams.message = "DLS version " ~ latestVersion.toString() ~ " available";
    requestParams.actions = [new MessageActionItem()];
    requestParams.actions[0].title = "Upgrade";

    auto id = Server.send("window/showMessageRequest", requestParams);
    auto threadName = "updater";
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
    dub = new Dub(pack.path.toString());
    dub.loadPackage();

    GeneratorSettings settings;
    BuildSettings buildSettings;

    version (Windows)
    {
        const arch = "x86_mscoff";
    }
    else
    {
        const arch = dub.defaultArchitecture;
    }

    auto compiler = getCompiler(dub.defaultCompiler);
    auto buildPlatform = compiler.determinePlatform(buildSettings, dub.defaultCompiler, arch);

    settings.platform = buildPlatform;
    settings.config = "application";
    settings.buildType = "release";
    settings.compiler = compiler;
    settings.buildSettings = buildSettings;
    settings.combined = false;
    settings.run = false;
    settings.force = false;
    settings.rdmd = false;
    settings.tempBuild = false;
    settings.parallelBuild = false;
    dub.generateProject("build", settings);
    latestDlsPath = buildNormalizedPath(pack.path.toString(), "dls");

    auto notificationParams = new ShowMessageParams();
    notificationParams.type = MessageType.info;
    notificationParams.message = "DLS " ~ latestVersion.toString() ~ " built";
    Server.send("window/showMessage", notificationParams);
}
