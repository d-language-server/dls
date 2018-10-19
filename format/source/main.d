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

int main(string[] args)
{
    import dls.tools.format : format;
    import std.file : readText;
    import std.outbuffer : OutBuffer;
    import std.stdio : stdin, stdout;

    string input;

    if (args.length > 1)
        input = readText(args[1]);
    else
    {
        auto buffer = new OutBuffer();

        foreach (chunk; stdin.byChunk(4096))
            buffer.write(chunk);

        input = buffer.toString();
    }

    stdout.rawWrite(format(input));
    return 0;
}
