module dls.protocol.messages.general;

import logger = std.experimental.logger;
import dls.protocol.interfaces;
import dls.server : Server;

@("")
auto initialize(InitializeParams params)
{
    import dls.tools.tools : Tools;
    import dls.util.uri : Uri;
    import std.algorithm : map;
    import std.array : array;

    auto result = new InitializeResult();

    Server.initialized = true;
    Server.initState = params;
    logger.log("Initializing server");
    Tools.initialize();

    Uri[] uris;

    if (!params.rootUri.isNull)
    {
        uris ~= new Uri(params.rootUri);
    }

    if (!params.workspaceFolders.isNull)
    {
        uris ~= params.workspaceFolders.map!(wf => new Uri(wf.uri)).array;
    }

    foreach (uri; uris)
    {
        Tools.symbolTool.importPath(uri);
        Tools.symbolTool.importSelections(uri);
    }

    with (result)
    {
        capabilities = new ServerCapabilities();

        with (capabilities)
        {
            textDocumentSync = new TextDocumentSyncOptions();
            completionProvider = new CompletionOptions();
            documentFormattingProvider = true;
            workspace = new ServerCapabilities.Workspace();

            with (textDocumentSync)
            {
                openClose = true;
                change = TextDocumentSyncKind.incremental;
            }

            with (completionProvider)
            {
                resolveProvider = false;
                triggerCharacters = ["."];
            }

            with (workspace)
            {
                workspaceFolders = new ServerCapabilities.Workspace.WorkspaceFolders();

                with (workspaceFolders)
                {
                    supported = true;
                    changeNotifications = JSONValue(true);
                }
            }
        }
    }

    return result;
}

@("")
void initialized(JSONValue nothing)
{
    import dls.updater : update;
    import std.concurrency : spawn;

    spawn(&update);

    const didChangeWatchedFiles = Server.initState.capabilities.workspace.didChangeWatchedFiles;

    if (!didChangeWatchedFiles.isNull && didChangeWatchedFiles.dynamicRegistration)
    {
        auto params = new RegistrationParams!DidChangeWatchedFilesRegistrationOptions();
        params.registrations ~= new Registration!DidChangeWatchedFilesRegistrationOptions();

        with (params.registrations[0])
        {
            id = "dls-registration-watch-dub-files";
            method = "workspace/didChangeWatchedFiles";
            registerOptions = new DidChangeWatchedFilesRegistrationOptions();

            with (registerOptions)
            {
                watchers = [new FileSystemWatcher(), new FileSystemWatcher()];
                watchers[0].globPattern = "**/dub.selections.json";
                watchers[1].globPattern = "**/dub.{json,sdl}";
            }
        }

        logger.log("Registering watchers");
        Server.send("client/registerCapability", params);
    }
}

@("")
auto shutdown(JSONValue nothing)
{
    logger.log("Shutting down server");
    Server.shutdown = true;
    return JSONValue(null);
}

@("")
void exit(JSONValue nothing)
{
    logger.log("Exiting server");
    Server.exit = true;
}

@("$")
void cancelRequest(JSONValue id)
{
}
