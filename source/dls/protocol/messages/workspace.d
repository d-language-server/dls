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

module dls.protocol.messages.workspace;

import dls.protocol.interfaces : SymbolInformation;
import dls.protocol.interfaces.workspace;
import std.json : JSONValue;
import std.typecons : Nullable;

void workspaceFolders(string id, Nullable!(WorkspaceFolder[]) folders)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : Workspace;
    import dls.protocol.state : initState;
    import dls.tools.tool : Tool;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    if (!folders.isNull)
    {
        ConfigurationItem[] items;

        foreach (workspaceFolder; folders)
        {
            auto uri = new Uri(workspaceFolder.uri);
            items ~= new ConfigurationItem(uri.toString().nullable);
            Tool.instance.updateConfig(uri, JSONValue());
        }

        immutable conf = !initState.capabilities.workspace.isNull
            && !initState.capabilities.workspace.configuration.isNull
            && initState.capabilities.workspace.configuration;

        if (conf)
        {
            send(Workspace.configuration, new ConfigurationParams(items));
        }
    }
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
    import dls.tools.tool : Tool;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        auto uri = new Uri(folder.uri);
        Tool.instance.removeConfig(uri);
    }
}

void configuration(string id, JSONValue[] configs)
{
    import dls.protocol.logger : logger;
    import dls.tools.tool : Tool;

    auto uris = null ~ Tool.instance.workspacesUris;

    logger.info("Updating workspace configurations");

    for (size_t i; i < configs.length && i < uris.length; ++i)
    {
        auto config = configs[i];

        if ("d" in config && "dls" in config["d"])
        {
            Tool.instance.updateConfig(uris[i], config["d"]["dls"]);
        }
    }
}

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.logger : logger;
    import dls.protocol.messages.methods : Workspace;
    import dls.protocol.state : initState;
    import dls.tools.configuration : Configuration;
    import dls.tools.tool : Tool;
    import std.typecons : Nullable, nullable;

    logger.info("Configuration changed");

    immutable conf = !initState.capabilities.workspace.isNull
        && !initState.capabilities.workspace.configuration.isNull
        && initState.capabilities.workspace.configuration;

    if (conf)
    {
        auto items = [new ConfigurationItem(Nullable!string(null))];

        foreach (uri; Tool.instance.workspacesUris)
        {
            items ~= new ConfigurationItem(uri.toString().nullable);
        }

        send(Workspace.configuration, new ConfigurationParams(items));
    }
    else if ("d" in params.settings && "dls" in params.settings["d"])
    {
        logger.info("Updating configuration");
        Tool.instance.updateConfig(null, params.settings["d"]["dls"]);
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
}

SymbolInformation[] symbol(WorkspaceSymbolParams params)
{
    return [];
}

JSONValue executeCommand(ExecuteCommandParams params)
{
    import dls.tools.command_tool : CommandTool;

    return CommandTool.instance.executeCommand(params.command,
            params.arguments.isNull ? [] : params.arguments.get());
}

void applyEdit(string id, ApplyWorkspaceEditResponse response)
{
}
