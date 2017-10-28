module protocol.interfaces.workspace;

public import protocol.definitions;

class DidChangeConfigurationParams
{
    JSONValue settings;
}

class DidChangeWatchedFilesParams
{
    FileEvent[] changes;
}

class FileEvent
{
    DocumentUri uri;
    FileChangeType type;
}

class WorkspaceSymbolParams
{
    string query;
}

enum FileChangeType
{
    created = 1,
    changed = 2,
    deleted = 3
}

class ExecuteCommandParams
{
    string command;
    Nullable!(JSONValue[]) arguments;
}

class ExecuteCommandRegistrationOptions
{
    string[] commands;
}

class ApplyWorkspaceEditParams
{
    WorkspaceEdit edit = new WorkspaceEdit();
}

class ApplyWorkspaceEditResponse
{
    bool applied;
}
