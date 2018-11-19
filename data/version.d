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

immutable dubPackageVersion = "DUB_PACKAGE_VERSION";

void main()
{
    import std.file : exists, readText, write;
    import std.path : buildNormalizedPath;
    import std.process : environment;

    const versionDataFile = buildNormalizedPath("data", "version.txt");
    const fileVersion = exists(versionDataFile) ? readText(versionDataFile) : "";
    const currentVersion = dubPackageVersion in environment ? environment[dubPackageVersion]
        : getVersionFromDescription();

    if (currentVersion != fileVersion)
    {
        write(versionDataFile, currentVersion);
    }
}

string getVersionFromDescription()
{
    import std.algorithm : find;
    import std.json : parseJSON;
    import std.process : execute;

    const desc = parseJSON(execute(["dub", "describe"]).output);
    return desc["packages"].array.find!(p => p["name"] == desc["rootPackage"])[0]["version"].str;
}
