module dls.protocol.jsonrpc;

import std.json : JSONValue;
import std.typecons : Nullable, Tuple, nullable, tuple;

private enum jsonrpcVersion = "2.0";
private enum eol = "\r\n";

abstract class Message
{
    string jsonrpc = jsonrpcVersion;
}

void send(T : Message)(T m)
{
    import dls.util.json : convertToJSON;
    import std.conv : to;
    import std.stdio : stdout;
    import std.utf : toUTF8;

    auto message = convertToJSON(m);
    auto messageString = message.get().toString();

    synchronized
    {
        foreach (chunk; ["Content-Length: ", messageString.length.to!string,
                eol, eol, messageString])
        {
            stdout.rawWrite(chunk.toUTF8());
        }

        stdout.flush();
    }
}

class RequestMessage : Message
{
    JSONValue id;
    string method;
    Nullable!JSONValue params;
}

class ResponseMessage : Message
{
    JSONValue id;
    Nullable!JSONValue result;
    Nullable!ResponseError error;
}

class ResponseError
{
    int code;
    string message;
    Nullable!JSONValue data;

    static auto fromErrorCode(ErrorCodes errorCode)
    {
        auto response = new ResponseError();
        response.code = errorCode[0];
        response.message = errorCode[1];
        return response.nullable;
    }
}

class NotificationMessage : Message
{
    string method;
    Nullable!JSONValue params;
}

enum ErrorCodes : Tuple!(int, string)
{
    parseError = tuple(-32_700, "Parse error"),
    invalidRequest = tuple(-32_600,
            "Invalid Request"),
    methodNotFound = tuple(
            -32_601, "Method not found"),
    invalidParams = tuple(-32_602,
            "Invalid params"),
    internalError = tuple(-32_603,
            "Internal error"),
    serverNotInitialized = tuple(-32_202,
            "Server not initialized"),
    unknownErrorCode = tuple(-32_201,
            "Unknown error"),
    requestCancelled = tuple(-32_800, "Request cancelled")
}

class CancelParams
{
    JSONValue id;
}
