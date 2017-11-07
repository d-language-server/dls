module dls.protocol.messages.general;

import dls.protocol.interfaces;
import dls.server;
import std.json;

@("")
auto initialize(InitializeParams params)
{
    auto result = new InitializeResult();

    Server.initialized = true;
    Server.initState = params;

    with (result)
    {
        capabilities = new ServerCapabilities();

        with (capabilities)
        {
            textDocumentSync = new TextDocumentSyncOptions();
            documentFormattingProvider = true;

            with (textDocumentSync)
            {
                openClose = true;
                change = TextDocumentSyncKind.incremental;
            }
        }
    }

    return result;
}

@("")
void initialized()
{
    // Nothing to do
}

@("")
auto shutdown()
{
    Server.shutdown = true;
    return JSONValue(null);
}

@("")
void exit()
{
    Server.exit = true;
}

@("$")
void cancelRequest(JSONValue id)
{
}
