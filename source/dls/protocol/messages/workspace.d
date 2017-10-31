module dls.protocol.messages.workspace;

import dls.protocol.configuration;
import dls.protocol.handlers;
import dls.protocol.interfaces;
import dls.util.json;
import std.json;

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        Configuration.set(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
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

@serverRequest void applyEdit(ApplyWorkspaceEditResponse response)
{
}
