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
        if (item.title.length > 0)
        {
            auto uri = new Uri(Util.messageRequestInfo[id][1]);
            Tools.symbolTool.upgradeSelections(uri);
        }

        break;

    case Util.ShowMessageRequestType.upgradeDls:
        send(locate(Util.messageRequestInfo[id][1]), item.title.length > 0);
        break;

    case Util.ShowMessageRequestType.showChangelog:
        if (item.title.length > 0)
        {
            browse(Util.messageRequestInfo[id][1]);
        }

        break;
    }

    Util.messageRequestInfo.remove(id);
}

abstract class Util
{
    import dls.protocol.interfaces : MessageType;
    import dls.protocol.jsonrpc : send;
    import std.array : array, replace;
    import std.algorithm : map;
    import std.conv : to;
    import std.json : JSONValue, parseJSON;
    import std.typecons : Tuple, tuple;

    static enum ShowMessageType
    {
        dlsBuildError = "dlsBuildError",
        dlsLinkError = "dlsLinkError"
    }

    static enum ShowMessageRequestType
    {
        upgradeSelections = "upgradeSelections",
        upgradeDls = "upgradeDls",
        showChangelog = "showChangelog"
    }

    shared alias ThreadMessageData = Tuple!(string, ShowMessageRequestType, string);

    private enum translationsJson = import("translations.json");
    private static JSONValue translations;
    private static string locale;
    private static Tuple!(ShowMessageRequestType, string)[string] messageRequestInfo;

    static this()
    {
        translations = parseJSON(translationsJson);
        locale = "en"; // TODO: add more locales and auto-detect system locale
    }

    static void sendMessage(ShowMessageType which, string[] args = [])
    {
        import dls.protocol.interfaces : ShowMessageParams;

        JSONValue tr = translations[which];
        auto title = tr["title"][locale].str;

        foreach (i; 0 .. args.length)
        {
            title = title.replace('$' ~ i.to!string, args[i]);
        }

        send("window/showMessage",
                new ShowMessageParams(tr["messageType"].integer.to!MessageType, title));
    }

    static string sendMessageRequest(ShowMessageRequestType which,
            string[] args = [], string[] hiddenItems = [])
    {
        import dls.protocol.interfaces : ShowMessageRequestParams;
        import std.algorithm : canFind, filter;
        import std.typecons : nullable;

        JSONValue tr = translations[which];
        auto title = tr["title"][locale].str;
        auto actions = tr["actions"].array
            .filter!(a => !hiddenItems.canFind(a["id"].str))
            .map!(a => new MessageActionItem(a["title"][locale].str));

        foreach (i; 0 .. args.length)
        {
            title = title.replace('$' ~ (i + 1).to!string, args[i]);
        }

        return send("window/showMessageRequest", new ShowMessageRequestParams(
                tr["messageType"].integer.to!MessageType, title, actions.array.nullable));
    }

    static string[] getActions(ShowMessageRequestType which)
    {
        return translations[which]["actions"].array.map!(a => a["title"][locale].str).array;
    }

    static void addMessageRequestType(string id, ShowMessageRequestType type, string data = null)
    {
        messageRequestInfo[id] = tuple(type, data);
    }
}
