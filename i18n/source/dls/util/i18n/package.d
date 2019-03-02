/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.util.i18n;

public import dls.util.i18n.constants;
import dls.protocol.interfaces : MessageType;
import std.json : JSONValue;

private enum translationsJson = import("translations.json");
private immutable JSONValue translations;
private immutable string locale;
private immutable defaultLocale = "en";

shared static this()
{
    import std.json : parseJSON;

    translations = parseJSON(translationsJson);
    locale = defaultLocale;

    version (Windows)
    {
        import core.sys.windows.windef : DWORD, ERROR_SUCCESS, LONG, HKEY;
        import core.sys.windows.winnt : KEY_READ;
        import core.sys.windows.winreg : HKEY_USERS, RegOpenKeyExA, RegQueryValueExA;
        import std.string : toStringz;

        HKEY hKey;
        auto regKeyCStr = toStringz(`.DEFAULT\Control Panel\International`);

        if (RegOpenKeyExA(HKEY_USERS, regKeyCStr, 0, KEY_READ, &hKey) != ERROR_SUCCESS)
        {
            return;
        }

        DWORD size = 32;
        auto buffer = new char[size];
        auto localeNameCStr = toStringz("LocaleName");

        if (RegQueryValueExA(hKey, localeNameCStr, null, null, buffer.ptr, &size) != ERROR_SUCCESS)
        {
            return;
        }

        if (size >= 2)
        {
            locale = buffer[0 .. 2].idup;
        }
    }
    else version (Posix)
    {
        import std.process : environment;

        auto lang = environment.get("LANG", defaultLocale);

        if (lang.length >= 2)
        {
            locale = lang[0 .. 2];
        }
    }
    else
    {
        locale = defaultLocale;
    }
}

string tr(Tr identifier, string[] args = [])
{
    import std.ascii : newline;
    import std.conv : text;
    import std.range : replace;

    auto message = translations[identifier];
    auto localizedMessage = message[locale in message ? locale : defaultLocale].str;

    foreach (i, arg; args)
    {
        localizedMessage = localizedMessage.replace('$' ~ text(i + 1), arg);
    }

    return localizedMessage.replace("$n", newline);
}

MessageType trType(Tr message)
{
    auto t = translations[message];
    return "_type" in t ? cast(MessageType) t["_type"].integer : MessageType.info;
}
