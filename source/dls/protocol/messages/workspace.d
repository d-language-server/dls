module dls.protocol.messages.workspace;

import logger = std.experimental.logger;
import dls.protocol.handlers : ServerRequest;
import dls.protocol.interfaces;
import dls.tools.tools : Tools;

@ServerRequest void workspaceFolders(Nullable!(WorkspaceFolder[]) folders)
{
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
}

@ServerRequest void configuration(JSONValue[] config)
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
    import dls.util.uri : Uri;
    import std.algorithm : canFind;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);

        logger.logf("File changed: %s", uri.path);

        if (["dub.json", "dub.sdl", "dub.selections.json"].canFind(baseName(uri.path)))
        {
            logger.logf("Importing dependencies from %s", dirName(uri.path));
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

@ServerRequest void applyEdit(ApplyWorkspaceEditResponse response)
{
}
