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

void main()
{
    import std.algorithm : sort;
    import std.file : append, readText, thisExePath, write;
    import std.format : format;
    import std.json : parseJSON;
    import std.path : buildNormalizedPath;
    import std.range : replace;

    immutable i18nDir = buildNormalizedPath(thisExePath, "..", "..", "i18n");
    immutable translationsPath = buildNormalizedPath(i18nDir, "data", "translations.json");
    immutable trModulePath = buildNormalizedPath(i18nDir, "source", "dls", "util", "constants.d");
    auto translations = parseJSON(readText(translationsPath));

    write(trModulePath, "module dls.util.constants;\n\n");
    append(trModulePath, "enum Tr : string\n{\n");

    foreach (key; sort(translations.object.keys))
    {
        append(trModulePath, format!"%s = \"%s\"%s\n"(key.replace(".", "_"), key, ","));
    }

    append(trModulePath, "}\n");
}
