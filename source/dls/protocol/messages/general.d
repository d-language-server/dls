module dls.protocol.messages.general;

import dls.protocol.interfaces.general;
import dls.server : Server;
import dls.util.logger : logger;
import std.json : JSONValue;
import std.typecons : nullable;

@("")
InitializeResult initialize(InitializeParams params)
{
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.algorithm : map, sort, uniq;
    import std.array : array;

    logger.info("Initializing server");
    Server.initialized = true;
    Server.initState = params;

    debug
    {
    }
    else
    {
        import dls.updater : cleanup;

        cleanup();
    }

    Tools.initialize();
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
        Tools.symbolTool.importPath(uri);
        Tools.symbolTool.importSelections(uri);
        Tools.analysisTool.addAnalysisConfigPath(uri);
    }

    auto result = new InitializeResult();

    with (result.capabilities)
    {
        textDocumentSync = new TextDocumentSyncOptions(true.nullable,
                TextDocumentSyncKind.incremental.nullable);
        textDocumentSync.save = new SaveOptions(false.nullable);
        completionProvider = new CompletionOptions(true.nullable, ["."].nullable);
        hoverProvider = true;
        documentFormattingProvider = true;
        definitionProvider = true;
        documentHighlightProvider = true;
        documentSymbolProvider = true;
        workspaceSymbolProvider = true;
        workspace = new ServerCapabilities.Workspace(new ServerCapabilities.Workspace.WorkspaceFolders(true.nullable,
                JSONValue(true).nullable).nullable);
    }

    return result;
}

@("")
void initialized(JSONValue nothing)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.interfaces : DidChangeWatchedFilesRegistrationOptions,
        FileSystemWatcher, Registration, RegistrationParams;

    debug
    {
    }
    else
    {
        import dls.updater : update;
        import std.concurrency : spawn;

        spawn(&update, cast(shared(InitializeParams.InitializationOptions)) Server.initOptions);
    }

    const didChangeWatchedFiles = Server.initState.capabilities.workspace.didChangeWatchedFiles;

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
        send("client/registerCapability",
                new RegistrationParams!DidChangeWatchedFilesRegistrationOptions([registration]));
    }
}

@("")
JSONValue shutdown(JSONValue nothing)
{
    logger.info("Shutting down server");
    Server.shutdown = true;
    return JSONValue(null);
}

@("")
void exit(JSONValue nothing)
{
    logger.info("Exiting server");
    Server.exit = true;
}

@("$")
void cancelRequest(JSONValue id)
{
}
