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

import dls.protocol.interfaces.client : RegistrationOptions;

final class WorkspaceFolder
{
    string uri;
    string name;

    @safe this() pure nothrow
    {
    }
}

final class DidChangeWorkspaceFoldersParams
{
    WorkspaceFoldersChangeEvent event;

    @safe this() pure nothrow
    {
    }
}

final class WorkspaceFoldersChangeEvent
{
    WorkspaceFolder[] added;
    WorkspaceFolder[] removed;

    @safe this() pure nothrow
    {
    }
}

final class DidChangeConfigurationParams
{
    import std.json : JSONValue;

    JSONValue settings;

    @safe this() pure nothrow
    {
    }
}

final class ConfigurationParams
{
    ConfigurationItem[] items;

    @safe this(ConfigurationItem[] items = ConfigurationItem[].init) pure nothrow
    {
        this.items = items;
    }
}

final class ConfigurationItem
{
    import std.typecons : Nullable;

    Nullable!string scopeUri;
    Nullable!string section;

    @safe this(Nullable!string scopeUri = Nullable!string.init,
            Nullable!string section = Nullable!string.init) pure nothrow
    {
        this.scopeUri = scopeUri;
        this.section = section;
    }
}

final class DidChangeWatchedFilesParams
{
    FileEvent[] changes;

    @safe this() pure nothrow
    {
    }
}

final class FileEvent
{
    import dls.protocol.definitions : DocumentUri;

    DocumentUri uri;
    FileChangeType type;

    @safe this() pure nothrow
    {
    }
}

enum FileChangeType : ubyte
{
    created = 1,
    changed = 2,
    deleted = 3
}

final class DidChangeWatchedFilesRegistrationOptions : RegistrationOptions
{
    FileSystemWatcher[] watchers;

    @safe this(FileSystemWatcher[] watchers = FileSystemWatcher[].init) pure nothrow
    {
        this.watchers = watchers;
    }
}

final class FileSystemWatcher
{
    import std.typecons : Nullable;

    string globPattern;
    Nullable!ubyte kind;

    @safe this(string globPattern = string.init, Nullable!ubyte kind = Nullable!ubyte.init) pure nothrow
    {
        this.globPattern = globPattern;
        this.kind = kind;
    }
}

enum WatchKind : ubyte
{
    create = 1,
    change = 2,
    delete_ = 4
}

final class WorkspaceSymbolParams
{
    string query;

    @safe this() pure nothrow
    {
    }
}

final class ExecuteCommandParams
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

    string command;
    Nullable!(JSONValue[]) arguments;

    @safe this() pure nothrow
    {
    }
}

final class ExecuteCommandRegistrationOptions : RegistrationOptions
{
    string[] commands;

    @safe this(string[] commands = string[].init) pure nothrow
    {
        this.commands = commands;
    }
}

final class ApplyWorkspaceEditParams
{
    import dls.protocol.definitions : WorkspaceEdit;

    WorkspaceEdit edit;

    @safe this(WorkspaceEdit edit = WorkspaceEdit.init) pure nothrow
    {
        this.edit = edit;
    }
}

final class ApplyWorkspaceEditResponse
{
    bool applied;

    @safe this() pure nothrow
    {
    }
}
