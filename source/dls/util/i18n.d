module dls.util.i18n;

import dls.constants : Tr;
import dls.protocol.interfaces : MessageType;
import std.conv : to;
import std.json : JSONValue;

private enum translationsJson = import("translations.json");
private immutable JSONValue translations;
private immutable string locale;

shared static this()
{
    import std.json : parseJSON;

    translations = parseJSON(translationsJson);
    locale = "en"; // TODO: add more locales and auto-detect system locale
}

string tr(Tr message, string[] args = [])
{
    import std.range : replace;

    auto title = translations[message]["title"][locale].str;

    foreach (i; 0 .. args.length)
    {
        title = title.replace('$' ~ (i + 1).to!string, args[i]);
    }

    return title;
}

MessageType trType(Tr message)
{
    auto t = translations[message];
    return "messageType" in t ? t["messageType"].integer.to!MessageType : MessageType.info;
}
