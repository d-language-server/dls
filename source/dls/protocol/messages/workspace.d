module dls.protocol.messages.workspace;

import dls.protocol.interfaces : SymbolInformation;
import dls.protocol.interfaces.workspace;
import dls.tools.tools : Tools;
import dls.util.uri : Uri;
import std.json : JSONValue;
import std.typecons : Nullable;

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
    import std.typecons : nullable;

    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        auto uri = new Uri(folder.uri);
        Tools.symbolTool.clearPath(uri);
        Tools.analysisTool.removeAnalysisConfigPath(uri);
    }
}

void configuration(string id, JSONValue[] config)
{
}

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    import dls.tools.configuration : Configuration;
    import dls.util.json : convertFromJSON;
    import std.experimental.logger : log;

    log("Configuration changed");

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        log("Applying new configuration");
        Tools.setConfiguration(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.server : Server;
    import dls.protocol.interfaces : MessageActionItem, MessageType,
        ShowMessageRequestParams;
    import dls.protocol.messages.window : Util;
    import std.algorithm : canFind;
    import std.experimental.logger : logf;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);
        const fileName = baseName(uri.path);

        logf("File changed: %s", uri.path);

        switch (fileName)
        {
        case "dub.json", "dub.sdl":
            auto id = Util.sendMessageRequest(
                    Util.ShowMessageRequestType.upgradeSelections, [uri.path]);
            Util.addMessageRequestType(id, Util.ShowMessageRequestType.upgradeSelections, uri);
            break;

        case "dub.selections.json":
            Tools.symbolTool.importSelections(uri);
            break;

        default:
            Tools.analysisTool.updateAnalysisConfigPath(Uri.fromPath(uri.path.dirName));
            break;
        }
    }
}

SymbolInformation[] symbol(WorkspaceSymbolParams params)
{
    return Tools.symbolTool.symbol(params.query);
}

JSONValue executeCommand(ExecuteCommandParams params)
{
    return JSONValue(null);
}

void applyEdit(string id, ApplyWorkspaceEditResponse response)
{
}
