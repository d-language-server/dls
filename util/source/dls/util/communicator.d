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
    bool hasPendingData();
    char[] read(size_t size);
    void write(const char[] data);
    void flush();
}

class StdioCommunicator : Communicator
{
    bool hasData()
    {
        import std.stdio : stdin;

        return !stdin.eof;
    }

    bool hasPendingData()
    {
        import std.stdio : stdin;

        version (Posix)
        {
            import core.stdc.stdio : EOF, getc, ungetc;
            import core.sys.posix.fcntl : F_GETFL, F_SETFL, O_NONBLOCK, fcntl;

            const flags = fcntl(stdin.fileno, F_GETFL);

            if (fcntl(stdin.fileno, F_SETFL, flags | O_NONBLOCK) == -1)
            {
                return false;
            }

            const c = getc(stdin.getFP());
            ungetc(c, stdin.getFP());
            fcntl(stdin.fileno, F_SETFL, flags);
            return c != EOF;
        }
        else
        {
            return false;
        }
    }

    char[] read(size_t size)
    {
        import std.stdio : stdin;

        static char[] buffer;
        buffer.length = size;
        return stdin.rawRead(buffer);
    }

    void write(const char[] data)
    {
        import std.stdio : stdout;

        stdout.rawWrite(data);
    }

    void flush()
    {
        import std.stdio : stdout;

        stdout.flush();
    }
}

class SocketCommunicator : Communicator
{
    import std.socket : Socket;

    private Socket _socket;

    this(ushort port)
    {
        import std.socket : AddressInfo, InternetAddress, SocketOption,
            SocketOptionLevel, TcpSocket;

        _socket = new TcpSocket(new InternetAddress("localhost", port));
        _socket.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
    }

    bool hasData()
    {
        synchronized (_socket)
        {
            return _socket.isAlive;
        }
    }

    bool hasPendingData()
    {
        import std.socket : SocketFlags;

        static char[1] buffer;
        ptrdiff_t result;

        synchronized (_socket)
        {
            _socket.blocking = false;
            result = _socket.receive(buffer, SocketFlags.PEEK);
            _socket.blocking = true;
        }

        return result != Socket.ERROR && result > 0;
    }

    char[] read(size_t size)
    {
        static char[] buffer;
        buffer.length = size;
        ptrdiff_t totalBytesReceived;
        ptrdiff_t bytesReceived;

        do
        {
            synchronized (_socket)
            {
                bytesReceived = _socket.receive(buffer);
            }

            if (bytesReceived != Socket.ERROR)
            {
                totalBytesReceived += bytesReceived;
            }
            else if (bytesReceived == 0)
            {
                buffer.length = totalBytesReceived;
                break;
            }
        }
        while (bytesReceived == Socket.ERROR || totalBytesReceived < size);

        return buffer;
    }

    void write(const char[] data)
    {
        ptrdiff_t totalBytesSent;
        ptrdiff_t bytesSent;

        do
        {
            synchronized (_socket)
            {
                bytesSent = _socket.send(data[totalBytesSent .. $]);
            }

            if (bytesSent != Socket.ERROR)
            {
                totalBytesSent += bytesSent;
            }
        }
        while (bytesSent == Socket.ERROR || totalBytesSent < data.length);
    }

    void flush()
    {
    }
}
