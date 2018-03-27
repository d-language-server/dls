module dls.protocol.messages.window;

import dls.protocol.interfaces;

void showMessageRequest(string id, MessageActionItem item)
{
    import logger = std.experimental.logger;
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.concurrency : locate, receiveOnly, send;
    import std.path : dirName;

    while (!(id in Util.messageRequestTypes))
    {
        auto data = receiveOnly!(Util.ThreadMessageData)();
        Util.addMessageRequestType(data[0], data[1], data[2]);
    }

    final switch (Util.messageRequestTypes[id][0])
    {
    case Util.ShowMessageRequestType.upgradeSelections:
        if (item.title == "Yes")
        {
            auto uri = new Uri(Util.messageRequestTypes[id][1]);
            Tools.symbolTool.upgradeSelections(uri);
        }

        break;

    case Util.ShowMessageRequestType.upgradeDls:
        send(locate(Util.messageRequestTypes[id][1]), item.title.length > 0);
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
        upgradeSelections,
        upgradeDls
    }

    shared alias ThreadMessageData = Tuple!(string, ShowMessageRequestType, string);

    private static Tuple!(ShowMessageRequestType, string)[string] messageRequestTypes;

    static void addMessageRequestType(string id, ShowMessageRequestType type, string data = null)
    {
        messageRequestTypes[id] = tuple(type, data);
    }
}
