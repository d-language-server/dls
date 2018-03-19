module dls.protocol.messages.workspace;

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

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        Tools.setConfiguration(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.util.uri : Uri;
    import std.algorithm : canFind;
    import std.path : baseName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);

        if (["dub.json", "dub.sdl", "dub.selections.json"].canFind(baseName(uri.path)))
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

@ServerRequest void applyEdit(ApplyWorkspaceEditResponse response)
{
}
