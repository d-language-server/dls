module dls.util.logger;

immutable logger = new LspLogger();

@safe shared static this()
{
    import std.experimental.logger : LogLevel, globalLogLevel;

    globalLogLevel = LogLevel.off;
}

private class LspLogger
{
    import dls.protocol.interfaces : MessageType;
    import std.format : format;

    @safe void log(in string message) const
    {
        sendMessage(message, MessageType.log);
    }

    @trusted void logf(Args...)(in string message, Args args) const
    {
        log(format(message, args));
    }

    @safe void warning(in string message) const
    {
        sendMessage(message, MessageType.warning);
    }

    @trusted void warningf(Args...)(in string message, Args args) const
    {
        warning(format(message, args));
    }

    @safe void error(in string message) const
    {
        sendMessage(message, MessageType.error);
    }

    @trusted void errorf(Args...)(in string message, Args args) const
    {
        error(format(message, args));
    }

    @trusted private void sendMessage(in string message, in MessageType type) const
    {
        import dls.protocol.interfaces : LogMessageParams;
        import dls.protocol.jsonrpc : send;
        import std.datetime : Clock;

        send("window/logMessage", new LogMessageParams(type,
                format!"%s\t%s"(Clock.currTime.toString(), message)));
    }
}
