/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.protocol.interfaces.workspace;

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

    this(ConfigurationItem[] items = ConfigurationItem[].init)
    {
        this.items = items;
    }
}

class ConfigurationItem
{
    Nullable!string scopeUri;
    Nullable!string section;

    this(Nullable!string scopeUri = Nullable!string.init,
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
    import dls.protocol.definitions : DocumentUri;

    DocumentUri uri;
    FileChangeType type;
}

enum FileChangeType : uint
{
    created = 1,
    changed = 2,
    deleted = 3
}

class DidChangeWatchedFilesRegistrationOptions : RegistrationOptionsBase
{
    FileSystemWatcher[] watchers;

    this(FileSystemWatcher[] watchers = FileSystemWatcher[].init)
    {
        this.watchers = watchers;
    }
}

class FileSystemWatcher
{
    string globPattern;
    Nullable!WatchKind kind;

    this(string globPattern = string.init, Nullable!WatchKind kind = Nullable!WatchKind.init)
    {
        this.globPattern = globPattern;
        this.kind = kind;
    }
}

enum WatchKind : uint
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

    this(string[] commands = string[].init)
    {
        this.commands = commands;
    }
}

class ApplyWorkspaceEditParams
{
    import dls.protocol.definitions : WorkspaceEdit;

    WorkspaceEdit edit;

    this(WorkspaceEdit edit = WorkspaceEdit.init)
    {
        this.edit = edit;
    }
}

class ApplyWorkspaceEditResponse
{
    bool applied;
}
