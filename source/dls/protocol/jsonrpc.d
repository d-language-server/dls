module dls.protocol.jsonrpc;

import dls.util.json;
import std.conv;
import std.json;
import std.stdio;
import std.typecons;
import std.utf;

private enum jsonrpcVersion = "2.0";
private enum eol = "\r\n";

abstract class Message
{
    string jsonrpc = jsonrpcVersion;
}

void send(T : Message)(T m)
{
    auto message = convertToJSON(m);
    auto messageString = message.get().toString();

    foreach (chunk; ["Content-Length: ", messageString.length.to!string, eol, eol, messageString])
    {
        stdout.rawWrite(chunk.toUTF8());
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

    static auto fromException(MessageException e)
    {
        auto response = new ResponseError();
        response.code = e.code;
        response.message = e.msg;
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

class MessageException : Exception
{
    immutable int code;

    this(string message, int code)
    {
        super(message);
        this.code = code;
    }
}

class CancelParams
{
    JSONValue id;
}
