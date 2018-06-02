module dls.protocol.jsonrpc;

import std.json : JSONValue;
import std.typecons : Nullable, Tuple, nullable, tuple;

private enum jsonrpcVersion = "2.0";
private enum eol = "\r\n";

@trusted private void send(T : Message)(T m)
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

@safe static void sendError(ErrorCodes error, RequestMessage request, JSONValue data)
{
    if (request !is null)
    {
        send(request.id, Nullable!JSONValue(), ResponseError.fromErrorCode(error, data).nullable);
    }
}

/++ Sends a request or a notification message. +/
@safe static string send(string method, Nullable!JSONValue params = Nullable!JSONValue())
{
    import dls.protocol.handlers : hasRegisteredHandler, pushHandler;
    import std.uuid : randomUUID;

    if (hasRegisteredHandler(method))
    {
        auto id = "dls-" ~ randomUUID().toString();
        pushHandler(id, method);
        send!RequestMessage(JSONValue(id), method, params, Nullable!ResponseError());
        return id;
    }

    send!NotificationMessage(JSONValue(), method, params, Nullable!ResponseError());
    return null;
}

@safe static string send(T)(string method, T params)
        if (!is(T : Nullable!JSONValue))
{
    import dls.util.json : convertToJSON;

    return send(method, convertToJSON(params).nullable);
}

/++ Sends a response message. +/
@safe static void send(JSONValue id, Nullable!JSONValue result,
        Nullable!ResponseError error = Nullable!ResponseError())
{
    send!ResponseMessage(id, null, result, error);
}

@safe private static void send(T : Message)(JSONValue id, string method,
        Nullable!JSONValue payload, Nullable!ResponseError error)
{
    import std.meta : AliasSeq;
    import std.traits : select;

    auto message = new T();

    __traits(getMember, message, select!(__traits(hasMember, T, "params"))("params", "result")) = payload;

    foreach (member; AliasSeq!("id", "method", "error"))
    {
        static if (__traits(hasMember, T, member))
        {
            mixin("message." ~ member ~ " = " ~ member ~ ";");
        }
    }

    send(message);
}

abstract class Message
{
    string jsonrpc = jsonrpcVersion;
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

    @safe static ResponseError fromErrorCode(ErrorCodes errorCode, JSONValue data)
    {
        auto response = new ResponseError();
        response.code = errorCode[0];
        response.message = errorCode[1];
        response.data = data;
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
