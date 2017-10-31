module dls.protocol.messages.workspace;

import dls.protocol.handlers;
import dls.protocol.interfaces;
import std.json;

void didChangeConfiguration(DidChangeConfigurationParams params)
{
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
