module dls.protocol.messages.window;

import dls.protocol.interfaces : MessageActionItem;

void showMessageRequest(string id, MessageActionItem item)
{
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.concurrency : locate, receiveOnly, send;
    import std.path : dirName;
    import std.process : browse;

    while (!(id in Util.messageRequestInfo))
    {
        auto data = receiveOnly!(Util.ThreadMessageData)();
        Util.addMessageRequestType(data[0], data[1], data[2]);
    }

    final switch (Util.messageRequestInfo[id][0])
    {
    case Util.ShowMessageRequestType.upgradeSelections:
        if (item.title.length)
        {
            auto uri = new Uri(Util.messageRequestInfo[id][1]);
            Tools.symbolTool.upgradeSelections(uri);
        }

        break;

    case Util.ShowMessageRequestType.upgradeDls:
        send(locate(Util.messageRequestInfo[id][1]), item.title.length > 0);
        break;

    case Util.ShowMessageRequestType.showChangelog:
        if (item.title.length)
        {
            browse(Util.messageRequestInfo[id][1]);
        }

        break;
    }

    Util.messageRequestInfo.remove(id);
}

abstract class Util
{
    import std.json : JSONValue;
    import std.typecons : Tuple, tuple;

    enum ShowMessageRequestType
    {
        upgradeSelections,
        upgradeDls,
        showChangelog
    }

    shared alias ThreadMessageData = Tuple!(string, ShowMessageRequestType, string);

    private static Tuple!(ShowMessageRequestType, string)[string] messageRequestInfo;

    static void addMessageRequestType(string id, ShowMessageRequestType type, string data = null)
    {
        messageRequestInfo[id] = tuple(type, data);
    }
}
