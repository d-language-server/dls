module dls.util.logger;

import dls.protocol.interfaces : InitializeParams, MessageType;
import std.conv : to;

shared auto logger = new shared LspLogger();
private immutable int[InitializeParams.Trace] traceToType;

shared static this()
{
    import std.experimental.logger : LogLevel, globalLogLevel;

    globalLogLevel = LogLevel.off;

    //dfmt off
    traceToType = [
        InitializeParams.Trace.off: 0,
        InitializeParams.Trace.messages: MessageType.warning.to!int,
        InitializeParams.Trace.verbose: MessageType.log.to!int
    ];
    //dfmt on
}

private shared class LspLogger
{
    import std.format : format;

    private int _messageType;

    @property void trace(in InitializeParams.Trace t)
    {
        _messageType = traceToType[t];
    }

    void info(in string message) const
    {
        sendMessage(message, MessageType.info);
    }

    void infof(Args...)(in string message, Args args) const
    {
        info(format(message, args));
    }

    void warning(in string message) const
    {
        sendMessage(message, MessageType.warning);
    }

    void warningf(Args...)(in string message, Args args) const
    {
        warning(format(message, args));
    }

    void error(in string message) const
    {
        sendMessage(message, MessageType.error);
    }

    void errorf(Args...)(in string message, Args args) const
    {
        error(format(message, args));
    }

    private void sendMessage(in string message, in MessageType type) const
    {
        import dls.protocol.interfaces : LogMessageParams;
        import dls.protocol.jsonrpc : send;
        import std.datetime : Clock;

        if (type <= _messageType)
        {
            send("window/logMessage", new LogMessageParams(type,
                    format!"[%.24s] %s"(Clock.currTime.toString(), message)));
        }
    }
}
