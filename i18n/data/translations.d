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

private immutable dubPackageDir = "DUB_PACKAGE_DIR";

void main()
{
    import std.algorithm : sort;
    import std.file : readText, write;
    import std.format : format;
    import std.json : parseJSON;
    import std.path : asRelativePath, buildNormalizedPath;
    import std.process : environment;
    import std.range : replace;

    immutable packageDir = environment[dubPackageDir];
    immutable translationsPath = buildNormalizedPath(packageDir, "data", "translations.json");
    immutable trModulePath = buildNormalizedPath(packageDir, "source", "dls",
            "util", "i18n", "constants.d");
    immutable trModuleContent = readText(trModulePath);
    auto translations = parseJSON(readText(translationsPath));
    string content;

    content ~= format(q{/+ This file is generated automatically by %s.d +/}, __MODULE__);
    content ~= "\n\n";
    content ~= q{module dls.util.i18n.constants;};
    content ~= "\n\n";
    content ~= q{enum Tr : string};
    content ~= "\n{\n";
    content ~= q{    _ = "### BAD TRANSLATION KEY ###",};
    content ~= "\n";

    foreach (key; sort(translations.object.keys))
    {
        content ~= format("    %s = \"%s\"%s\n", key.replace(".", "_"), key, ",");
    }

    content ~= "}\n";

    if (content != trModuleContent)
    {
        write(trModulePath, content);
    }
}
