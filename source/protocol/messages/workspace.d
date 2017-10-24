module protocol.messages.workspace;

import protocol.definitions;
import protocol.handlers;
import protocol.jsonrpc;
import std.json;
import std.typecons;

void didChangeConfiguration(Nullable!JSONValue jsonParams)
{
}

void didChangeWatchedFiles(Nullable!JSONValue jsonParams)
{
}

ResponseData symbol(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData executeCommand(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

void applyEdit(Nullable!JSONValue jsonResult, Nullable!ResponseError error)
{
}
