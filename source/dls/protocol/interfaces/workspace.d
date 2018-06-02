module dls.protocol.interfaces.workspace;

import dls.protocol.definitions : DocumentUri, MarkupKind, WorkspaceEdit;
import dls.protocol.interfaces.client : RegistrationOptionsBase;
import dls.util.constructor : Constructor;
import std.json : JSONValue;
import std.typecons : Nullable;

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

    @safe this(ConfigurationItem[] items = ConfigurationItem[].init)
    {
        this.items = items;
    }
}

class ConfigurationItem
{
    Nullable!string scopeUri;
    Nullable!string section;

    @safe this(Nullable!string scopeUri = Nullable!string.init,
            Nullable!string section = Nullable!string.init)
    {
        this.scopeUri = scopeUri;
        this.section = section;
    }
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

    @safe this(FileSystemWatcher[] watchers = FileSystemWatcher[].init)
    {
        this.watchers = watchers;
    }
}

class FileSystemWatcher
{
    string globPattern;
    Nullable!WatchKind kind;

    @safe this(string globPattern = string.init, Nullable!WatchKind kind = Nullable!WatchKind.init)
    {
        this.globPattern = globPattern;
        this.kind = kind;
    }
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

    @safe this(string[] commands = string[].init)
    {
        this.commands = commands;
    }
}

class ApplyWorkspaceEditParams
{
    WorkspaceEdit edit;

    @safe this(WorkspaceEdit edit = WorkspaceEdit.init)
    {
        this.edit = edit;
    }
}

class ApplyWorkspaceEditResponse
{
    bool applied;
}
