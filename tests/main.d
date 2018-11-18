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

import dls.util.communicator : Communicator;

private class TestCommunicator : Communicator
{
    private string _currentOutput;

    bool hasData()
    {
        return false;
    }

    char[] read(size_t size)
    {
        return new char[size];
    }

    void write(in char[] buffer)
    {
        _currentOutput ~= buffer;
    }

    void flush()
    {
        _currentOutput = "";
    }
}

void main()
{
    import dls.server : Server;
    import dls.util.communicator : communicator;

    communicator = new shared TestCommunicator();
    Server.loop();
}
