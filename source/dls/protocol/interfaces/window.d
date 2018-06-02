module dls.protocol.interfaces.window;

import std.typecons : Nullable;

class ShowMessageParams
{
    MessageType type;
    string message;

    @safe this(MessageType type = MessageType.init, string message = string.init)
    {
        this.type = type;
        this.message = message;
    }
}

enum MessageType
{
    error = 1,
    warning = 2,
    info = 3,
    log = 4
}

class ShowMessageRequestParams : ShowMessageParams
{
    Nullable!(MessageActionItem[]) actions;

    @safe this(MessageType type = MessageType.init, string message = string.init,
            Nullable!(MessageActionItem[]) actions = Nullable!(MessageActionItem[]).init)
    {
        super(type, message);
        this.actions = actions;
    }
}

class MessageActionItem
{
    string title;

    @safe this(string title = string.init)
    {
        this.title = title;
    }
}

alias LogMessageParams = ShowMessageParams;
