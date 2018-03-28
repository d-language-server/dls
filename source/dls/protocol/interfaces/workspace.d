module dls.protocol.interfaces.workspace;

public import dls.protocol.definitions;
import dls.protocol.interfaces.client : RegistrationOptionsBase;
import dls.util.constructor : Constructor;

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

enum FileChangeType
{
    created = 1,
    changed = 2,
    deleted = 3
}

class DidChangeWatchedFilesRegistrationOptions : RegistrationOptionsBase
{
    FileSystemWatcher[] watchers;
}

class FileSystemWatcher
{
    string globPattern;
    Nullable!WatchKind kind;
}

enum WatchKind
{
    create = 1,
    change = 2,
    delete_ = 4
}

class WorkspaceSymbolParams
{
    string query;
}

class ExecuteCommandParams
{
    string command;
    Nullable!(JSONValue[]) arguments;
}

class ExecuteCommandRegistrationOptions : RegistrationOptionsBase
{
    string[] commands;
}

class ApplyWorkspaceEditParams
{
    WorkspaceEdit edit;

    mixin Constructor!ApplyWorkspaceEditParams;
}

class ApplyWorkspaceEditResponse
{
    bool applied;
}
