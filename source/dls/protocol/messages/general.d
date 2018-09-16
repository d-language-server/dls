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
    import dls.server : Server;
    import dls.protocol.state : initOptions, initState;
    import dls.tools.symbol_tool : useCompatCompletionItemKinds,
        useCompatSymbolKinds;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.logger : logger;
    import dls.util.uri : Uri;
    import std.algorithm : map, sort, uniq;
    import std.array : array;
    import std.typecons : Nullable, nullable;

    logger.info("Initializing server");
    initState = params;
    Server.initialized = true;
    AnalysisTool.initialize();
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

    if (params.capabilities.textDocument.completion.isNull
            || params.capabilities.textDocument.completion.completionItemKind.isNull
            || params.capabilities.textDocument.completion.completionItemKind.valueSet.isNull)
    {
        useCompatCompletionItemKinds();
    }
    else
    {
        useCompatCompletionItemKinds(
                params.capabilities.textDocument.completion.completionItemKind.valueSet);
    }

    if (params.capabilities.workspace.symbol.isNull || params.capabilities.workspace.symbol.symbolKind.isNull
            || params.capabilities.workspace.symbol.symbolKind.valueSet.isNull)
    {
        useCompatSymbolKinds();
    }
    else
    {
        useCompatSymbolKinds(params.capabilities.workspace.symbol.symbolKind.valueSet);
    }

    if (params.capabilities.textDocument.documentSymbol.isNull
            || params.capabilities.textDocument.documentSymbol.symbolKind.isNull
            || params.capabilities.textDocument.documentSymbol.symbolKind.valueSet.isNull)
    {
        useCompatSymbolKinds();
    }
    else
    {
        useCompatSymbolKinds(params.capabilities.textDocument.documentSymbol.symbolKind.valueSet);
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
        AnalysisTool.instance.addAnalysisConfigPath(uri);
    }

    auto result = new InitializeResult();

    with (result.capabilities)
    {
        textDocumentSync = new TextDocumentSyncOptions(true.nullable,
                TextDocumentSyncKind.incremental.nullable);
        textDocumentSync.save = new SaveOptions(false.nullable);
        hoverProvider = initOptions.capabilities.hover;
        completionProvider = initOptions.capabilities.completion ? new CompletionOptions(true.nullable,
                ["."].nullable).nullable : Nullable!CompletionOptions();
        definitionProvider = initOptions.capabilities.definition;
        typeDefinitionProvider = initOptions.capabilities.definition;
        referencesProvider = initOptions.capabilities.references;
        documentHighlightProvider = initOptions.capabilities.documentHighlight;
        documentSymbolProvider = initOptions.capabilities.documentSymbol;
        workspaceSymbolProvider = initOptions.capabilities.workspaceSymbol;
        documentFormattingProvider = initOptions.capabilities.documentFormatting;
        renameProvider = initOptions.capabilities.rename
            ? new RenameOptions(true.nullable) : Nullable!RenameOptions();
        workspace = new ServerCapabilities.Workspace(new ServerCapabilities.Workspace.WorkspaceFolders(true.nullable,
                JSONValue(true).nullable).nullable);
    }

    return result;
}

@("")
void initialized(JSONValue nothing)
{
    import dls.protocol.interfaces : DidChangeWatchedFilesRegistrationOptions,
        FileSystemWatcher, Registration, RegistrationParams;
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : Client;
    import dls.protocol.state : initOptions, initState;
    import dls.server : Server;
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

    const didChangeWatchedFiles = initState.capabilities.workspace.didChangeWatchedFiles;

    if (!didChangeWatchedFiles.isNull && didChangeWatchedFiles.dynamicRegistration)
    {
        logger.info("Registering watchers");
        auto watchers = [
            new FileSystemWatcher("**/dub.selections.json"),
            new FileSystemWatcher("**/dub.{json,sdl}"), new FileSystemWatcher("**/*.ini")
        ];
        auto registrationOptions = new DidChangeWatchedFilesRegistrationOptions(watchers);
        auto registration = new Registration!DidChangeWatchedFilesRegistrationOptions(
                "dls-registration-watch-dub-files",
                "workspace/didChangeWatchedFiles", registrationOptions.nullable);
        send(Client.registerCapability,
                new RegistrationParams!DidChangeWatchedFilesRegistrationOptions([registration]));
    }
}

@("")
JSONValue shutdown(JSONValue nothing)
{
    import dls.server : Server;
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;
    import dls.util.logger : logger;

    logger.info("Shutting down server");
    Server.shutdown = true;
    AnalysisTool.shutdown();
    FormatTool.shutdown();
    SymbolTool.shutdown();
    return JSONValue(null);
}

@("")
void exit(JSONValue nothing)
{
    import dls.server : Server;
    import dls.util.logger : logger;

    logger.info("Exiting server");
    Server.exit = true;
}

@("$")
void cancelRequest(JSONValue id)
{
}
