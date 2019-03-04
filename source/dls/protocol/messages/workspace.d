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
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
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
            SymbolTool.instance.importPath(uri);
            AnalysisTool.instance.addAnalysisConfig(uri);
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
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.tools.tool : Tool;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        auto uri = new Uri(folder.uri);
        Tool.instance.removeConfig(uri);
        SymbolTool.instance.clearPath(uri);
        AnalysisTool.instance.removeAnalysisConfig(uri);
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
    import dls.protocol.interfaces : FileChangeType, PublishDiagnosticsParams;
    import dls.protocol.jsonrpc : send;
    import dls.protocol.logger : logger;
    import dls.protocol.messages.methods : TextDocument;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.document : Document;
    import dls.util.uri : Uri, sameFile;
    import std.algorithm : canFind, filter, startsWith;
    import std.file : exists, isFile;
    import std.path : baseName, dirName, extension, pathSplitter;

    foreach (event; params.changes.filter!(event => event.type == FileChangeType.deleted))
    {
        auto workspaceUri = SymbolTool.instance.getWorkspace(new Uri(event.uri));

        if (workspaceUri !is null && !exists(workspaceUri.path))
        {
            SymbolTool.instance.clearPath(workspaceUri);
        }
    }

    outer: foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);
        auto dirPath = dirName(uri.path);

        foreach (part; pathSplitter(dirPath))
        {
            if (part.startsWith('.'))
            {
                continue outer;
            }
        }

        auto dirUri = Uri.fromPath(dirPath);

        logger.info("Resource %s: %s", event.type, uri.path);

        if (exists(uri.path) && !isFile(uri.path))
        {
            continue;
        }

        switch (baseName(uri.path))
        {
        case "dub.json", "dub.sdl":
            if (event.type != FileChangeType.deleted)
            {
                SymbolTool.instance.importDubProject(dirUri);
            }

            continue;

        case "dub.selections.json":
            if (event.type != FileChangeType.deleted)
            {
                SymbolTool.instance.importDubSelections(dirUri);
            }

            continue;

        case ".gitmodules":
            if (event.type != FileChangeType.deleted)
            {
                SymbolTool.instance.importGitSubmodules(dirUri);
            }

            continue;

        default:
            break;
        }

        switch (extension(uri.path))
        {
        case ".d", ".di":
            Uri[] discarded;

            if (event.type == FileChangeType.deleted)
            {
                send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri, []));
            }
            else if (!Document.uris.canFind!sameFile(uri)
                    && AnalysisTool.instance.getScannableFilesUris(discarded)
                    .canFind!sameFile(uri))
            {
                send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri,
                        AnalysisTool.instance.diagnostics(uri)));
            }

            continue;

        case ".ini":
            AnalysisTool.instance.updateAnalysisConfig(dirUri);
            continue;

        default:
            break;
        }
    }
}

SymbolInformation[] symbol(WorkspaceSymbolParams params)
{
    import dls.tools.symbol_tool : SymbolTool;

    return SymbolTool.instance.symbol(params.query);
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
