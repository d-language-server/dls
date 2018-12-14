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
    import dls.protocol.state : initOptions, initState;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.command_tool : CommandTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.logger : logger;
    import dls.util.uri : Uri;
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

    foreach (uri; uris.sort!q{a.path < b.path}
            .uniq!q{a.path == b.path})
    {
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
    import dls.protocol.interfaces : DidChangeWatchedFilesRegistrationOptions,
        FileSystemWatcher, Registration, RegistrationParams, WatchKind;
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : Client;
    import dls.protocol.state : initOptions, initState;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.util.logger : logger;
    import std.typecons : nullable;

    debug
    {
    }
    else
    {
        import dls.updater : update;
        import std.concurrency : spawn;

        spawn(&update, initOptions.autoUpdate);
    }

    const didChangeWatchedFiles = !initState.capabilities.workspace.isNull
        && !initState.capabilities.workspace.didChangeWatchedFiles.isNull
        && initState.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration;
    ubyte watchAllEvents = WatchKind.create + WatchKind.change + WatchKind.delete_;

    if (didChangeWatchedFiles)
    {
        logger.info("Registering watchers");
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
        auto registration = new Registration!DidChangeWatchedFilesRegistrationOptions(
                "dls-registration-watch-dub-files",
                "workspace/didChangeWatchedFiles", registrationOptions.nullable);
        send(Client.registerCapability,
                new RegistrationParams!DidChangeWatchedFilesRegistrationOptions([registration]));
    }

    AnalysisTool.instance.scanAllWorkspaces();
}

@("")
JSONValue shutdown(JSONValue nothing)
{
    import dls.protocol.definitions : TextDocumentIdentifier;
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.command_tool : CommandTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.document : Document;
    import dls.util.logger : logger;

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
    import dls.server : Server;
    import dls.util.logger : logger;

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
void cancelRequest(JSONValue id)
{
}
