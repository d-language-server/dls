module dls.protocol.messages.workspace;

import logger = std.experimental.logger;
import dls.protocol.interfaces;
import dls.tools.tools : Tools;
import dls.util.uri : Uri;

void workspaceFolders(string id, Nullable!(WorkspaceFolder[]) folders)
{
    if (!folders.isNull)
    {
        foreach (workspaceFolder; folders)
        {
            auto uri = new Uri(workspaceFolder.uri);
            Tools.symbolTool.importPath(uri);
            Tools.symbolTool.importSelections(uri);
            Tools.analysisTool.addAnalysisConfigPath(uri);
        }
    }
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
    // TODO: separate caches depending on the workspace folder to be abe to remove them afterwards
    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        Tools.analysisTool.removeAnalysisConfigPath(new Uri(folder.uri));
    }
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
    import std.algorithm : canFind;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);
        const fileName = baseName(uri.path);

        logger.logf("File changed: %s", uri.path);

        switch (fileName)
        {
        case "dub.json", "dub.sdl":
            auto p = new ShowMessageRequestParams();
            p.type = MessageType.info;
            p.message = fileName ~ " was updated. Upgrade dependencies ?";
            p.actions = [new MessageActionItem(), new MessageActionItem()];
            p.actions[0].title = "Yes";
            p.actions[1].title = "No";

            auto id = Server.send("window/showMessageRequest", p);
            Util.addMessageRequestType(id, Util.ShowMessageRequestType.upgradeSelections, uri);
            break;

        case "dub.selections.json":
            Tools.symbolTool.importSelections(uri);
            break;

        default:
            Tools.analysisTool.updateAnalysisConfigPath(new Uri(uri.path.dirName));
            break;
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
