module dls.protocol.messages.window;

import dls.protocol.interfaces;

void showMessageRequest(string id, MessageActionItem item)
{
    import logger = std.experimental.logger;
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.path : dirName;

    final switch (Util.messageRequestTypes[id][0])
    {
    case Util.ShowMessageRequestType.upgradeSelections:
        if (item.title == "Yes")
        {
            auto uri = new Uri(Util.messageRequestTypes[id][1].str);
            Tools.codeCompleter.upgradeSelections(uri);
        }

        break;
    }

    Util.messageRequestTypes.remove(id);
}

abstract class Util
{
    import std.json : JSONValue;
    import std.typecons : Tuple, tuple;

    enum ShowMessageRequestType
    {
        upgradeSelections
    }

    private static Tuple!(ShowMessageRequestType, JSONValue)[string] messageRequestTypes;

    static void addMessageRequestType(string id, ShowMessageRequestType type,
            JSONValue data = JSONValue())
    {
        messageRequestTypes[id] = tuple(type, data);
    }
}
