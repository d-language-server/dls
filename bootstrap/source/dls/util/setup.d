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

module dls.util.setup;

void initialSetup()
{
    version (Windows)
    {
        import std.algorithm : splitter;
        import std.file : exists;
        import std.path : buildNormalizedPath, dirName;
        import std.process : environment;

        version (X86_64)
        {
            enum binDir = "bin64";
        }
        else
        {
            enum binDir = "bin";
        }

        auto pathParts = splitter(environment["PATH"], ';');

        foreach (path; pathParts)
        {
            if (exists(buildNormalizedPath(path, "dmd.exe")))
            {
                environment["PATH"] = buildNormalizedPath(dirName(path), binDir)
                    ~ ';' ~ environment["PATH"];
                return;
            }
        }

        foreach (path; pathParts)
        {
            if (exists(buildNormalizedPath(path, "ldc2.exe")))
            {
                environment["PATH"] = path ~ ';' ~ environment["PATH"];
            }
        }
    }
}
