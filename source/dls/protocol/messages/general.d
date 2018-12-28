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

module dls.protocol.messages.general;

import dls.protocol.interfaces.general;
import std.json : JSONValue;

@("")
InitializeResult initialize(InitializeParams params)
{
    import dls.protocol.interfaces : CodeActionKind;
    import dls.protocol.logger : logger;
    import dls.protocol.state : initOptions, initState;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.command_tool : CommandTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.tools.tool : Tool;
    import dls.util.uri : Uri, filenameCmp, sameFile;
    import std.algorithm : map, sort, uniq;
    import std.array : array;
    import std.typecons : Nullable, nullable;

    initState = params;
    logger.info("Initializing server");
    AnalysisTool.initialize();
    CommandTool.initialize();
    FormatTool.initialize();
    SymbolTool.initialize();

    debug
    {
    }
    else
    {
        import dls.updater : cleanup;
        import std.concurrency : spawn;

        spawn(&cleanup);
    }

    Uri[] uris;

    if (!params.rootUri.isNull)
    {
        uris ~= new Uri(params.rootUri);
    }
    else if (!params.rootPath.isNull)
    {
        uris ~= Uri.fromPath(params.rootPath);
    }

    if (!params.workspaceFolders.isNull)
    {
        uris ~= params.workspaceFolders.map!(wf => new Uri(wf.uri)).array;
    }

    foreach (uri; uris.sort!((a, b) => filenameCmp(a, b) < 0)
            .uniq!sameFile)
    {
        Tool.updateConfig(uri, JSONValue());
        SymbolTool.instance.importPath(uri);
        AnalysisTool.instance.addAnalysisConfig(uri);
    }

    auto result = new InitializeResult();

    with (result.capabilities)
    {
        import std.json : JSONValue;
        import std.typecons : Nullable;

        textDocumentSync = new TextDocumentSyncOptions(true.nullable,
                TextDocumentSyncKind.incremental.nullable);
        textDocumentSync.save = new SaveOptions(false.nullable);
        hoverProvider = initOptions.capabilities.hover;
        completionProvider = initOptions.capabilities.completion
            ? new CompletionOptions(true.nullable, ["."].nullable) : Nullable!CompletionOptions();
        definitionProvider = initOptions.capabilities.definition;
        typeDefinitionProvider = initOptions.capabilities.definition;
        referencesProvider = initOptions.capabilities.references;
        documentHighlightProvider = initOptions.capabilities.documentHighlight;
        documentSymbolProvider = initOptions.capabilities.documentSymbol;
        workspaceSymbolProvider = initOptions.capabilities.workspaceSymbol;
        codeActionProvider = initOptions.capabilities.codeAction;
        documentFormattingProvider = initOptions.capabilities.documentFormatting;
        documentRangeFormattingProvider = initOptions.capabilities.documentRangeFormatting;
        documentOnTypeFormattingProvider = initOptions.capabilities.documentOnTypeFormatting
            ? new DocumentOnTypeFormattingOptions(";") : Nullable!DocumentOnTypeFormattingOptions();
        renameProvider = initOptions.capabilities.rename
            ? new RenameOptions(true.nullable) : Nullable!RenameOptions();
        executeCommandProvider = initOptions.capabilities.codeAction
            ? new ExecuteCommandOptions(CommandTool.instance.commands)
            : Nullable!ExecuteCommandOptions();
        workspace = new ServerCapabilities.Workspace(new ServerCapabilities.Workspace.WorkspaceFolders(true.nullable,
                JSONValue(true).nullable).nullable);
    }

    Server.initialized = true;
    return result;
}

@("")
void initialized(JSONValue nothing)
{
    import dls.protocol.interfaces : ConfigurationItem, ConfigurationParams,
        DidChangeWatchedFilesRegistrationOptions, FileSystemWatcher,
        Registration, RegistrationParams, WatchKind;
    import dls.protocol.jsonrpc : send;
    import dls.protocol.logger : logger;
    import dls.protocol.messages.methods : Client, Workspace;
    import dls.protocol.state : initOptions, initState;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.tool : Tool;
    import std.typecons : Nullable, nullable;

    debug
    {
    }
    else
    {
        import dls.updater : update;
        import std.concurrency : spawn;

        spawn(&update, initOptions.autoUpdate);
    }

    if (!initState.capabilities.workspace.isNull)
    {
        const didChangeWatchedFiles = !initState.capabilities.workspace.didChangeWatchedFiles.isNull
            && initState.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration;
        ubyte watchAllEvents = WatchKind.create + WatchKind.change + WatchKind.delete_;

        if (didChangeWatchedFiles)
        {
            logger.info("Registering file watchers");
            //dfmt off
            auto watchers = [
                new FileSystemWatcher("**/dub.{json,sdl}", watchAllEvents.nullable),
                new FileSystemWatcher("**/dub.selections.json", watchAllEvents.nullable),
                new FileSystemWatcher("**/.gitmodules", watchAllEvents.nullable),
                new FileSystemWatcher("**/*.ini", watchAllEvents.nullable),
                new FileSystemWatcher("**/*.{d,di}", watchAllEvents.nullable)
            ];
            //dfmt on
            auto registrationOptions = new DidChangeWatchedFilesRegistrationOptions(watchers);
            auto registration = new Registration!DidChangeWatchedFilesRegistrationOptions("dls-file-watchers",
                    "workspace/didChangeWatchedFiles", registrationOptions.nullable);
            send(Client.registerCapability,
                    new RegistrationParams!DidChangeWatchedFilesRegistrationOptions([registration]));
        }

        const configuration = !initState.capabilities.workspace.configuration.isNull
            && initState.capabilities.workspace.configuration;

        if (configuration)
        {
            auto items = [new ConfigurationItem(Nullable!string(null))];

            foreach (uri; Tool.workspacesUris)
            {
                items ~= new ConfigurationItem(uri.toString().nullable);
            }

            send(Workspace.configuration, new ConfigurationParams(items));
        }
    }

    AnalysisTool.instance.scanAllWorkspaces();
}

@("")
JSONValue shutdown(JSONValue nothing)
{
    import dls.protocol.definitions : TextDocumentIdentifier;
    import dls.protocol.logger : logger;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.command_tool : CommandTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.document : Document;

    logger.info("Shutting down server");
    Server.initialized = false;
    AnalysisTool.shutdown();
    CommandTool.shutdown();
    FormatTool.shutdown();
    SymbolTool.shutdown();

    foreach (uri; Document.uris)
    {
        Document.close(new TextDocumentIdentifier(uri));
    }

    return JSONValue(null);
}

@("")
void exit(JSONValue nothing)
{
    import dls.protocol.logger : logger;
    import dls.server : Server;

    if (Server.initialized)
    {
        logger.warning("Shutdown not requested prior to exit");
        shutdown(JSONValue());
        Server.initialized = true;
    }

    logger.info("Exiting server");
    Server.exit = true;
}

@("$")
void cancelRequest(CancelParams params)
{
    import dls.server : Server;

    Server.cancel(params.id);
}
