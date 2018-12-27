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

module dls.protocol.logger;

import dls.protocol.interfaces : InitializeParams, MessageType;

private shared _logger = new shared LspLogger();
private immutable int[InitializeParams.Trace] traceToType;
private immutable string[MessageType] messageSeverity;
private immutable logMessageFormat = "[%.24s] [%s] %s";

shared static this()
{
    import std.conv : to;
    import std.experimental.logger : LogLevel, globalLogLevel;

    globalLogLevel = LogLevel.off;

    //dfmt off
    traceToType = [
        InitializeParams.Trace.off      : 0,
        InitializeParams.Trace.messages : MessageType.warning.to!int,
        InitializeParams.Trace.verbose  : MessageType.info.to!int
    ];

    messageSeverity = [
        MessageType.log     : "D",
        MessageType.info    : "I",
        MessageType.warning : "W",
        MessageType.error   : "E"
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
    import std.format : format;

    private int _messageType;

    @property void trace(const InitializeParams.Trace t)
    {
        _messageType = traceToType[t];
    }

    void log(Args...)(const string message, const Args args) const
    {
        sendMessage(format(message, args), MessageType.log);
    }

    void info(Args...)(const string message, const Args args) const
    {
        sendMessage(format(message, args), MessageType.info);
    }

    void warning(Args...)(const string message, const Args args) const
    {
        sendMessage(format(message, args), MessageType.warning);
    }

    void error(Args...)(const string message, const Args args) const
    {
        sendMessage(format(message, args), MessageType.error);
    }

    private void sendMessage(const string message, const MessageType type) const
    {
        import dls.protocol.interfaces : LogMessageParams;
        import dls.protocol.jsonrpc : send;
        import dls.protocol.messages.methods : Window;
        import dls.protocol.state : initOptions;
        import std.datetime : Clock;
        import std.file : mkdirRecurse;
        import std.format : format;
        import std.path : dirName;
        import std.stdio : File;

        if (initOptions.logFile.length > 0)
        {
            static bool firstLog = true;

            if (firstLog)
            {
                mkdirRecurse(dirName(initOptions.logFile));
            }

            synchronized
            {
                auto log = File(initOptions.logFile, firstLog ? "w" : "a");
                log.writefln(logMessageFormat, Clock.currTime.toString(),
                        messageSeverity[type], message);
                log.flush();
            }

            if (firstLog)
            {
                firstLog = false;
            }
        }

        if (type <= _messageType)
        {
            send(Window.logMessage, new LogMessageParams(type, format(logMessageFormat,
                    Clock.currTime.toString(), messageSeverity[type], message)));
        }
    }
}
