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
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;

    if (!folders.isNull)
    {
        foreach (workspaceFolder; folders)
        {
            auto uri = new Uri(workspaceFolder.uri);
            Tools.symbolTool.importPath(uri);
            Tools.analysisTool.addAnalysisConfigPath(uri);
        }
    }
}

void didChangeWorkspaceFolders(DidChangeWorkspaceFoldersParams params)
{
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    workspaceFolders(null, params.event.added.nullable);

    foreach (folder; params.event.removed)
    {
        auto uri = new Uri(folder.uri);
        Tools.symbolTool.clearPath(uri);
        Tools.analysisTool.removeAnalysisConfigPath(uri);
    }
}

void configuration(string id, JSONValue[] config)
{
}

void didChangeConfiguration(DidChangeConfigurationParams params)
{
    import dls.tools.configuration : Configuration;
    import dls.tools.tools : Tools;
    import dls.util.json : convertFromJSON;
    import dls.util.logger : logger;

    logger.info("Configuration changed");

    if ("d" in params.settings && "dls" in params.settings["d"])
    {
        logger.info("Applying new configuration");
        Tools.setConfiguration(convertFromJSON!Configuration(params.settings["d"]["dls"]));
    }
}

void didChangeWatchedFiles(DidChangeWatchedFilesParams params)
{
    import dls.util.constants : Tr;
    import dls.protocol.interfaces : FileChangeType;
    import dls.protocol.messages.window : Util;
    import dls.tools.tools : Tools;
    import dls.util.logger : logger;
    import dls.util.uri : Uri;
    import std.path : baseName, dirName;

    foreach (event; params.changes)
    {
        auto uri = new Uri(event.uri);

        logger.infof("File changed: %s", uri.path);

        switch (baseName(uri.path))
        {
        case "dub.json", "dub.sdl":
            if (baseName(dirName(uri.path)) != ".dub"
                    && event.type != FileChangeType.deleted)
            {
                auto id = Util.sendMessageRequest(Tr.app_upgradeSelections,
                        [Tr.app_upgradeSelections_upgrade], [uri.path]);
                Util.bindMessageToRequestId(id, Tr.app_upgradeSelections, uri);
                Tools.symbolTool.importPath(uri);
            }

            break;

        case "dub.selections.json":
            Tools.symbolTool.importSelections(uri);
            break;

        default:
            Tools.analysisTool.updateAnalysisConfigPath(Uri.fromPath(uri.path.dirName));
            break;
        }
    }
}

SymbolInformation[] symbol(WorkspaceSymbolParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.symbol(params.query);
}

JSONValue executeCommand(ExecuteCommandParams params)
{
    return JSONValue(null);
}

void applyEdit(string id, ApplyWorkspaceEditResponse response)
{
}
