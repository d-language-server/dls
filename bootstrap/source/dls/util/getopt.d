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

module dls.util.getopt;

import std.getopt : Option;

void printHelp(const char[] title, const Option[] options, void delegate(const char[]) sink)
{
    import std.ascii : newline;
    import std.algorithm : map, maxElement;

    sink(title);
    sink(newline);

    immutable longest = maxElement(options.map!(o => o.optLong.length + (o.optShort.length > 0
            ? o.optShort.length + 1 : 0)));

    foreach (option; options)
    {
        auto lineSize = option.optLong.length;
        sink(option.optLong);

        if (option.optShort.length > 0)
        {
            lineSize += option.optShort.length + 1;
            sink("|");
            sink(option.optShort);
        }

        if (option.help.length > 0)
        {
            auto spaces = new char[longest + 1 - lineSize];
            spaces[] = ' ';
            sink(spaces);
            sink(option.help);
        }

        sink(newline);
    }
}
