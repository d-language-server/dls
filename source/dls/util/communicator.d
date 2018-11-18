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

// Socket can't be used with a shared aliasing.
// However, the communicator's methods are all called either from the main
// thread, or from inside a synchronized block, so __gshared is ok.
private __gshared Communicator _communicator;

@property Communicator communicator()
{
    return _communicator;
}

@property void communicator(Communicator c)
{
    assert(_communicator is null);
    _communicator = c;
}

interface Communicator
{
    bool hasData();
    char[] read(size_t size);
    void write(in char[] data);
    void flush();
}

class StdioCommunicator : Communicator
{
    import std.stdio : stdin, stdout;

    bool hasData()
    {
        return !stdin.eof;
    }

    char[] read(size_t size)
    {
        static char[] buffer;
        buffer.length = size;
        return stdin.rawRead(buffer);
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

class SocketCommunicator : Communicator
{
    import std.socket : Socket;

    private Socket _socket;

    this(ushort port)
    {
        import std.socket : AddressFamily, AddressInfo, InternetAddress, ProtocolType, SocketType;

        _socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        _socket.connect(new InternetAddress("127.0.0.1", port));
    }

    bool hasData()
    {
        synchronized (_socket)
        {
            return _socket.isAlive;
        }
    }

    char[] read(size_t size)
    {
        static char[] buffer;
        buffer.length = size;
        ptrdiff_t result;

        synchronized (_socket)
        {
            result = _socket.receive(buffer);
        }

        if (result == 0 || result == Socket.ERROR)
        {
            buffer.length = 0;
        }

        return buffer;
    }

    void write(in char[] data)
    {
        synchronized (_socket)
        {
            _socket.send(data);
        }
    }

    void flush()
    {
    }
}
