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

module dls.util.logger;

import dls.protocol.interfaces : InitializeParams;

private shared _logger = new shared LspLogger();
private immutable int[InitializeParams.Trace] traceToType;
private immutable logMessageFormat = "[%.24s] %s";

shared static this()
{
    import dls.protocol.interfaces : MessageType;
    import std.conv : to;
    import std.experimental.logger : LogLevel, globalLogLevel;

    globalLogLevel = LogLevel.off;

    //dfmt off
    traceToType = [
        InitializeParams.Trace.off      : 0,
        InitializeParams.Trace.messages : MessageType.warning.to!int,
        InitializeParams.Trace.verbose  : MessageType.log.to!int
    ];
    //dfmt on
}

@property shared(LspLogger) logger()
{
    return _logger;
}

private shared class LspLogger
{
    import dls.protocol.interfaces : MessageType;

    private int _messageType;

    @property void trace(const InitializeParams.Trace t)
    {
        _messageType = traceToType[t];
    }

    void info(const string message) const
    {
        sendMessage(message, MessageType.info);
    }

    void infof(Args...)(const string message, const Args args) const
    {
        import std.format : format;

        info(format(message, args));
    }

    void warning(const string message) const
    {
        sendMessage(message, MessageType.warning);
    }

    void warningf(Args...)(const string message, const Args args) const
    {
        import std.format : format;

        warning(format(message, args));
    }

    void error(const string message) const
    {
        sendMessage(message, MessageType.error);
    }

    void errorf(Args...)(const string message, const Args args) const
    {
        import std.format : format;

        error(format(message, args));
    }

    private void sendMessage(const string message, const MessageType type) const
    {
        import dls.protocol.interfaces : LogMessageParams;
        import dls.protocol.jsonrpc : send;
        import dls.protocol.messages.methods : Window;
        import dls.protocol.state : initOptions;
        import std.datetime : Clock;
        import std.format : format;
        import std.stdio : File;

        if (initOptions.logFile.length > 0)
        {
            static bool firstLog = true;

            synchronized
            {
                auto log = File(initOptions.logFile, firstLog ? "w" : "a");
                log.writefln(logMessageFormat, Clock.currTime.toString(), message);
                log.flush();
            }

            if (firstLog)
            {
                firstLog = false;
            }
        }

        if (type <= _messageType)
        {
            send(Window.logMessage, new LogMessageParams(type,
                    format(logMessageFormat, Clock.currTime.toString(), message)));
        }
    }
}
