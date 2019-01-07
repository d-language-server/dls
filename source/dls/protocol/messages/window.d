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

module dls.protocol.messages.window;

import dls.protocol.interfaces : MessageActionItem;
import std.typecons : Nullable;

void showMessageRequest(string id, Nullable!MessageActionItem item)
{
    import dls.protocol.logger : logger;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.constants : Tr;
    import dls.util.i18n : tr;
    import dls.util.uri : Uri;
    import std.concurrency : locate, receiveOnly, send;
    import std.process : browse;

    while (id !in Util.messageRequestInfo)
    {
        auto data = receiveOnly!(Util.ThreadMessageData)();
        Util.bindMessageToRequestId(data[0], data[1], data[2]);
    }

    if (!item.isNull)
    {
        switch (Util.messageRequestInfo[id][0])
        {
        case Tr.app_upgradeSelections:
            if (item.title == tr(Tr.app_upgradeSelections_upgrade))
            {
                auto uri = new Uri(Util.messageRequestInfo[id][1]);
                SymbolTool.instance.upgradeSelections(uri);
            }

            break;

        case Tr.app_upgradeDls:
            send(locate(Util.messageRequestInfo[id][1]),
                    item.title == tr(Tr.app_upgradeDls_upgrade));
            break;

        case Tr.app_showChangelog:
            if (item.title == tr(Tr.app_showChangelog_show))
            {
                logger.info("Opening changelog in browser");
                browse(Util.messageRequestInfo[id][1]);
            }

            break;

        default:
            assert(false, Util.messageRequestInfo[id][0] ~ " cannot be handled as requests");
        }
    }

    Util.messageRequestInfo.remove(id);
}

final abstract class Util
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : Window;
    import dls.util.constants : Tr;
    import dls.util.i18n : tr, trType;
    import std.array : array;
    import std.algorithm : map;
    import std.typecons : Tuple, tuple;

    shared alias ThreadMessageData = Tuple!(string, Tr, string);

    private static Tuple!(Tr, string)[string] messageRequestInfo;

    static void sendMessage(Tr message, string[] args = [])
    {
        import dls.protocol.interfaces : ShowMessageParams;

        send(Window.showMessage, new ShowMessageParams(trType(message), tr(message, args)));
    }

    static string sendMessageRequest(Tr message, Tr[] actions, string[] args = [])
    {
        import dls.protocol.interfaces : ShowMessageRequestParams;
        import std.typecons : nullable;

        return send(Window.showMessageRequest, new ShowMessageRequestParams(trType(message),
                tr(message, args), actions.map!(a => new MessageActionItem(tr(a,
                args))).array.nullable));
    }

    static void bindMessageToRequestId(string id, Tr message, string data = null)
    {
        messageRequestInfo[id] = tuple(message, data);
    }
}
