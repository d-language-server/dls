module protocol.interfaces.window;

public import protocol.definitions;

class ShowMessageParams
{
    MessageType type;
    string message;
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
}

class MessageActionItem
{
    string title;
}

alias LogMessageParams = ShowMessageParams;
