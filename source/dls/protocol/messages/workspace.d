module dls.protocol.messages.workspace;

import logger = std.experimental.logger;
import dls.protocol.interfaces;
import dls.tools.tools : Tools;

void workspaceFolders(string id, Nullable!(WorkspaceFolder[]) folders)
{
    import dls.util.uri : Uri;
    import std.path : dirName;

    if (!folders.isNull)
    {
        foreach (workspaceFolder; folders)
        {
            auto uri = new Uri(workspaceFolder.uri);
            Tools.codeCompleter.importPath(uri);
            Tools.codeCompleter.importSelections(uri);
        }
    }
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
    workspaceFolders(null, params.event.added.nullable);
}

void configuration(string id, JSONValue[] config)
{
}

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    import dls.tools.configuration : Configuration;
    import dls.util.json : convertFromJSON;

    logger.log("Configuration changed");

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        logger.log("Applying new configuration");
        Tools.setConfiguration(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.server : Server;
    import dls.protocol.messages.window : Util;
    import dls.util.uri : Uri;
    import std.algorithm : canFind;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);
        auto fileName = baseName(uri.path);

        logger.logf("File changed: %s", uri.path);

        if (["dub.json", "dub.sdl"].canFind(fileName))
        {
            auto p = new ShowMessageRequestParams();
            p.type = MessageType.info;
            p.message = fileName ~ " was updated. Upgrade dependencies ?";
            p.actions = [new MessageActionItem(), new MessageActionItem()];
            p.actions[0].title = "Yes";
            p.actions[1].title = "No";
            auto id = Server.send("window/showMessageRequest", p);
            Util.addMessageRequestType(id, Util.ShowMessageRequestType.upgradeSelections, uri);
        }
        else if (fileName == "dub.selections.json")
        {
            Tools.codeCompleter.importSelections(uri);
        }
    }
}

auto symbol(WorkspaceSymbolParams params)
{
    SymbolInformation[] result;
    return result;
}

auto executeCommand(ExecuteCommandParams params)
{
    auto result = JSONValue(null);
    return result;
}

void applyEdit(string id, ApplyWorkspaceEditResponse response)
{
}
