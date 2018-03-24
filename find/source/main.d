int main()
{
    import dub.dependency : Dependency;
    import dub.dub : Dub, FetchOptions;
    import dub.internal.vibecompat.core.log : LogLevel, setLogLevel;
    import std.stdio : stdout;

    setLogLevel(LogLevel.none);

    auto dub = new Dub();
    FetchOptions fetchOpts;
    fetchOpts |= FetchOptions.forceBranchUpgrade;
    stdout.write(dub.fetch("dls", Dependency(">=0.0.0"),
            dub.defaultPlacementLocation, fetchOpts).path);

    return 0;
}
