module dls.protocol.interfaces.workspace;

public import dls.protocol.definitions;

class WorkspaceFolder
{
    string uri;
    string name;
}

class DidChangeWorkspaceFoldersParams
{
    WorkspaceFoldersChangeEvent event;
}

class WorkspaceFoldersChangeEvent
{
    WorkspaceFolder[] added;
    WorkspaceFolder[] removed;
}

class DidChangeConfigurationParams
{
    JSONValue settings;
}

class ConfigurationParams
{
    ConfigurationItem[] items;
}

class ConfigurationItem
{
    Nullable!string scopeUri;
    Nullable!string section;
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
