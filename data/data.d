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
    import std.file : exists, readText, write;
    import std.path : buildNormalizedPath;
    import std.process : environment;

    immutable dataPath = buildNormalizedPath(environment["DUB_PACKAGE_DIR"], "data");

    //dfmt off
    immutable fileFillers = [
        "dls-version.txt" : environment.get("DUB_PACKAGE_VERSION", getVersionFromDescription()),
        "build-platform.txt": environment.get("DUB_PLATFORM", "unknown-build-platform"),
        "build-arch.txt": environment.get("DUB_ARCH", "unknown-build-arch"),
        "build-type.txt": environment.get("DUB_BUILD_TYPE", "unknown-build-type"),
        "compiler-version.txt" : getCompilerVersion()
    ];
    //dfmt on

    foreach (file, newContent; fileFillers)
    {
        immutable dataFile = buildNormalizedPath(dataPath, file);
        immutable oldContent = exists(dataFile) ? readText(dataFile) : "";

        if (newContent != oldContent)
        {
            write(dataFile, newContent);
        }
    }
}

string getCompilerVersion()
{
    import std.process : environment, execute;
    import std.regex : matchFirst, regex;

    return execute([environment["DC"], "--version"]).output.matchFirst(
            regex(`\d+\.\d+\.\d+`)).front;
}

string getVersionFromDescription()
{
    import std.algorithm : find;
    import std.json : parseJSON;
    import std.process : Config, environment, execute;

    immutable describe = execute(["dub", "describe"], null, Config.none, size_t.max, environment["DUB_PACKAGE_DIR"]);
    immutable desc = parseJSON(describe.output);
    return desc["packages"].array.find!(p => p["name"] == desc["rootPackage"])[0]["version"].str;
}
