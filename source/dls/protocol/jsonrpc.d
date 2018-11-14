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

module dls.protocol.jsonrpc;

import dls.util.constants : Tr;
import std.json : JSONValue;
import std.typecons : Nullable, Tuple, tuple;

private enum jsonrpcVersion = "2.0";
private enum eol = "\r\n";

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
    long code;
    string message;
    Nullable!JSONValue data;

    static ResponseError fromErrorCode(ErrorCodes errorCode, JSONValue data)
    {
        import dls.util.i18n : tr;
        import std.typecons : nullable;

        auto response = new ResponseError();
        response.code = errorCode[0];
        response.message = tr(errorCode[1]);
        response.data = data;
        return response.nullable;
    }
}

class NotificationMessage : Message
{
    string method;
    Nullable!JSONValue params;
}

enum ErrorCodes : Tuple!(long, Tr)
{
    parseError = tuple(-32_700L, Tr.app_rpc_errorCodes_parseError),
    invalidRequest = tuple(-32_600L, Tr.app_rpc_errorCodes_invalidRequest),
    methodNotFound = tuple(-32_601L, Tr.app_rpc_errorCodes_methodNotFound),
    invalidParams = tuple(-32_602L, Tr.app_rpc_errorCodes_invalidParams),
    internalError = tuple(-32_603L, Tr.app_rpc_errorCodes_internalError),
    serverNotInitialized = tuple(-32_202L, Tr.app_rpc_errorCodes_serverNotInitialized),
    unknownErrorCode = tuple(-32_201L, Tr.app_rpc_errorCodes_unknownErrorCode),
    requestCancelled = tuple(-32_800L, Tr.app_rpc_errorCodes_requestCancelled)
}

class CancelParams
{
    JSONValue id;
}

class InvalidParamsException : Exception
{
    this(string msg)
    {
        super("Invalid parameters: " ~ msg);
    }
}

void sendError(ErrorCodes error, RequestMessage request, JSONValue data)
{
    import std.typecons : nullable;

    if (request !is null)
    {
        send(request.id, Nullable!JSONValue(), ResponseError.fromErrorCode(error, data).nullable);
    }
}

/++ Sends a request or a notification message. +/
string send(string method, Nullable!JSONValue params = Nullable!JSONValue())
{
    import dls.protocol.handlers : hasResponseHandler, pushHandler;
    import std.uuid : randomUUID;

    if (hasResponseHandler(method))
    {
        auto id = randomUUID().toString();
        pushHandler(id, method);
        send!RequestMessage(JSONValue(id), method, params, Nullable!ResponseError());
        return id;
    }

    send!NotificationMessage(JSONValue(), method, params, Nullable!ResponseError());
    return null;
}

string send(T)(string method, T params) if (!is(T : Nullable!JSONValue))
{
    import dls.util.json : convertToJSON;
    import std.typecons : nullable;

    return send(method, convertToJSON(params).nullable);
}

/++ Sends a response message. +/
void send(JSONValue id, Nullable!JSONValue result,
        Nullable!ResponseError error = Nullable!ResponseError())
{
    send!ResponseMessage(id, null, result, error);
}

private void send(T : Message)(JSONValue id, string method,
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

private void send(T : Message)(T m)
{
    import dls.util.communicator : communicator;
    import dls.util.json : convertToJSON;
    import std.conv : to;
    import std.utf : toUTF8;

    auto message = convertToJSON(m);
    auto messageString = message.get().toString();

    synchronized
    {
        foreach (chunk; ["Content-Length: ", messageString.length.to!string,
                eol, eol, messageString])
        {
            communicator.write(chunk.toUTF8());
        }

        communicator.flush();
    }
}
