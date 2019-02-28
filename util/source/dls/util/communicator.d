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

import std.stdio : File;

// Socket can't be used with a shared aliasing.
// However, the communicator's methods are all called either from the main
// thread, or from inside a synchronized block, so __gshared is ok.
private __gshared Communicator _communicator;
private __gshared File _stdin;
private __gshared File _stdout;

shared static this()
{
    import std.stdio : stdin, stdout;

    _stdin = stdin;
    _stdout = stdout;

    version (Windows)
    {
        stdin = File("NUL", "rb");
        stdout = File("NUL", "wb");
    }
    else version (Posix)
    {
        stdin = File("/dev/null", "rb");
        stdout = File("/dev/null", "wb");
    }
}

shared static ~this()
{
    if (_communicator !is null)
    {
        destroy(communicator);
    }
}

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
    char[] read(const size_t size);
    void write(const char[] data);
    void flush();
}

class StdioCommunicator : Communicator
{
    import std.parallelism : Task, TaskPool;

    private bool _checkPending;
    private TaskPool _pool;
    private Task!(readChar)* _background;

    static char readChar()
    {
        if (_stdin.isOpen && !_stdin.eof)
        {
            static char[1] buffer;
            auto result = _stdin.rawRead(buffer);

            if (result.length > 0)
            {
                return result[0];
            }
        }

        throw new Exception("No input data");
    }

    this(bool checkPendingData)
    {
        _checkPending = checkPendingData;

        if (checkPendingData)
        {
            _pool = new TaskPool(1);
            _pool.isDaemon = true;
            startBackground();
        }
    }

    ~this()
    {
        if (_checkPending)
        {
            _pool.stop();
        }
    }

    bool hasData()
    {
        return _stdin.isOpen && !_stdin.eof;
    }

    bool hasPendingData()
    {
        try
        {
            return _checkPending && _background.done;
        }
        catch (Exception e)
        {
            return false;
        }
    }

    char[] read(const size_t size)
    {
        if (size == 0)
        {
            return [];
        }

        static char[] buffer;
        buffer.length = size;

        if (!_checkPending)
        {
            return _stdin.rawRead(buffer);
        }

        try
        {
            buffer[0] = _background.yieldForce();
        }
        catch (Exception e)
        {
            return (_stdin.isOpen && !_stdin.eof) ? _stdin.rawRead(buffer) : [];
        }
        finally
        {
            startBackground();
        }

        if (size > 1)
        {
            buffer = buffer[0 .. _stdin.rawRead(buffer[1 .. $]).length + 1];
        }

        return buffer;
    }

    void write(const char[] data)
    {
        _stdout.rawWrite(data);
    }

    void flush()
    {
        _stdout.flush();
    }

    private void startBackground()
    {
        import std.parallelism : task;

        if (_checkPending && _stdin.isOpen && !_stdin.eof)
        {
            _background = task!readChar;
            _pool.put(_background);
        }
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

    char[] read(const size_t size)
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
