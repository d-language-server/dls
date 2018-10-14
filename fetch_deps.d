void main()
{
    import std.file : readText;
    import std.json : parseJSON;
    import std.process : execute;

    const deps = parseJSON(readText("dub.selections.json"));

    foreach (package_, version_; deps["versions"].object)
        execute(["dub", "fetch", package_, "--version=" ~ version_.str]);
}
