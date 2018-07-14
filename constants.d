void main()
{
    import std.algorithm : sort;
    import std.file : append, readText, write;
    import std.format : format;
    import std.json : parseJSON;
    import std.path : buildNormalizedPath;
    import std.range : replace;

    immutable translationsPath = buildNormalizedPath("data", "translations.json");
    immutable trModulePath = buildNormalizedPath("source", "dls", "constants.d");
    auto translations = parseJSON(readText(translationsPath));

    write(trModulePath, "module dls.constants;\n\n");
    append(trModulePath, "enum Tr : string\n{\n");

    auto keys = sort(translations.object.keys);

    foreach (key; keys)
    {
        append(trModulePath, format!"%s = \"%s\"%s\n"(key.replace(".", "_"),
                key, key == keys[$ - 1] ? "" : ","));
    }

    append(trModulePath, "}\n");
}
