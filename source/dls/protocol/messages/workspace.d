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
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.uri : Uri;

    if (!folders.isNull)
    {
        foreach (workspaceFolder; folders)
        {
            auto uri = new Uri(workspaceFolder.uri);
            SymbolTool.instance.importPath(uri);
            AnalysisTool.instance.addAnalysisConfig(uri);
        }
    }
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        auto uri = new Uri(folder.uri);
        SymbolTool.instance.clearPath(uri);
        AnalysisTool.instance.removeAnalysisConfig(uri);
    }
}

void configuration(string id, JSONValue[] config)
{
}

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    import dls.tools.configuration : Configuration;
    import dls.tools.tool : Tool;
    import dls.util.json : convertFromJSON;
    import dls.util.logger : logger;

    logger.info("Configuration changed");

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        logger.info("Applying new configuration");
        Tool.configuration = convertFromJSON!Configuration(params.settings["d"]["dls"]);
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.protocol.interfaces : FileChangeType, PublishDiagnosticsParams;
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : TextDocument;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.logger : logger;
    import dls.util.uri : Uri;
    import std.path : baseName, dirName, extension;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);
        auto dirUri = Uri.fromPath(dirName(uri.path));

        logger.infof("File changed: %s", uri.path);

        switch (baseName(uri.path))
        {
        case "dub.json", "dub.sdl":
            if (baseName(dirName(uri.path)) != ".dub"
                    && event.type != FileChangeType.deleted)
            {
                SymbolTool.instance.importDubProject(dirUri);
            }

            continue;

        case "dub.selections.json":
            SymbolTool.instance.importDubSelections(dirUri);
            continue;

        default:
            break;
        }

        switch (extension(uri.path))
        {
        case ".d", ".di":
            if (event.type != FileChangeType.deleted)
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
