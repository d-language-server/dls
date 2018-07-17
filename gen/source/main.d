void main()
{
    import std.algorithm : sort;
    import std.file : append, readText, write;
    import std.format : format;
    import std.json : parseJSON;
    import std.path : buildNormalizedPath;
    import std.range : replace;

    immutable i18nDir = buildNormalizedPath(__FILE__, "..", "..", "..", "i18n");
    immutable translationsPath = buildNormalizedPath(i18nDir, "data", "translations.json");
    immutable trModulePath = buildNormalizedPath(i18nDir, "source", "dls", "util", "constants.d");
    auto translations = parseJSON(readText(translationsPath));

    write(trModulePath, "module dls.util.constants;\n\n");
    append(trModulePath, "enum Tr : string\n{\n");

    auto keys = sort(translations.object.keys);

    foreach (key; keys)
    {
        append(trModulePath, format!"%s = \"%s\"%s\n"(key.replace(".", "_"), key, ","));
    }

    append(trModulePath, "}\n");
}
