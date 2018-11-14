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

module dls.util.communicator;

private shared Communicator _communicator;

@property shared(Communicator) communicator()
{
    return _communicator;
}

@property void communicator(shared(Communicator) c)
{
    assert(_communicator is null);
    _communicator = c;
}

shared interface Communicator
{
    bool hasData();
    char[] read(size_t size);
    void write(in char[]);
    void flush();
}

shared class StdioCommunicator : Communicator
{
    import std.stdio : stdin, stdout;

    bool hasData()
    {
        return !stdin.eof;
    }

    char[] read(size_t size)
    {
        return stdin.rawRead(new char[size]);
    }

    void write(in char[] data)
    {
        stdout.rawWrite(data);
    }

    void flush()
    {
        stdout.flush();
    }
}
