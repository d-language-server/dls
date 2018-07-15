module dls.protocol.messages.workspace;

import dls.protocol.interfaces : SymbolInformation;
import dls.protocol.interfaces.workspace;
import dls.tools.tools : Tools;
import dls.util.logger : logger;
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

    logger.info("Configuration changed");

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        logger.info("Applying new configuration");
        Tools.setConfiguration(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.util.constants : Tr;
    import dls.protocol.messages.window : Util;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);

        logger.infof("File changed: %s", uri.path);

        switch (baseName(uri.path))
        {
        case "dub.json", "dub.sdl":
            if (baseName(dirName(uri.path)) != ".dub")
            {
                auto id = Util.sendMessageRequest(Tr.upgradeSelections,
                        [Tr.upgradeSelections_upgrade], [uri.path]);
                Util.bindMessageToRequestId(id, Tr.upgradeSelections, uri);
            }

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
