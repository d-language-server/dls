module protocol.messages.general;

import protocol.interfaces;
import server;
import std.json;

@("")
auto initialize(InitializeParams params)
{
    auto result = new InitializeResult();

    Server.initialized = true;
    Server.initState = cast(shared(InitializeParams)) params;

    with (result)
    {
        capabilities = new ServerCapabilities();

        with (capabilities)
        {
            textDocumentSync = new TextDocumentSyncOptions();

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
