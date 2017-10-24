module protocol.messages.general;

import protocol.definitions;
import protocol.handlers;
import protocol.interfaces;
import server;
import std.json;
import std.typecons;
import util.json;

@("")
ResponseData initialize(Nullable!JSONValue jsonParams)
{
    shared params = convertFromJSON!InitializeParams(jsonParams);
    auto result = new InitializeResult();

    Server.initialized = true;
    Server.initState = params;

    with (result)
    {
        capabilities = new ServerCapabilities();

        with (capabilities)
        {
            textDocumentSync = new TextDocumentSyncOptions();
        }
    }

    return ResponseData(convertToJSON(result));
}

@("")
void initialized(Nullable!JSONValue jsonParams)
{
    // Nothing to do
}

@("")
ResponseData shutdown(Nullable!JSONValue jsonParams)
{
    Server.shutdown = true;
    return ResponseData();
}

@("")
void exit(Nullable!JSONValue jsonParams)
{
    Server.exit = true;
}

@("$")
void cancelRequest(Nullable!JSONValue jsonParams)
{
}
