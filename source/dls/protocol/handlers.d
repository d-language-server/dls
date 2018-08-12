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

module dls.protocol.handlers;

import std.json : JSONValue;
import std.traits : Parameters, ReturnType, isSomeFunction;
import std.typecons : Nullable;

alias RequestHandler = Nullable!JSONValue delegate(Nullable!JSONValue);
alias NotificationHandler = void delegate(Nullable!JSONValue);
alias ResponseHandler = void delegate(string id, Nullable!JSONValue);

private shared RequestHandler[string] requestHandlers;
private shared NotificationHandler[string] notificationHandlers;
private shared ResponseHandler[string] responseHandlers;
private shared ResponseHandler[string] runtimeResponseHandlers;

/++
Checks if a function is correct handler function. These will only be registered
at startup time and will never be unregistered.
+/
template isHandler(func...)
{
    enum isHandler = __traits(compiles, isSomeFunction!func) && isSomeFunction!func;
}

class HandlerNotFoundException : Exception
{
    this(string method)
    {
        super("No handler found for method " ~ method);
    }
}

/++
Checks if a method has a response handler registered for it. Used to determine
if the server should send a request or a notification to the client (if the
method has a response handler, then the server will expect a response and thus
send a request instead of a notification).
+/
bool hasResponseHandler(string method)
{
    return (method in responseHandlers) !is null;
}

/++
Registers a new handler of any kind (`RequestHandler`, `NotificationHandler` or
`ResponseHandler`).
+/
void pushHandler(F)(string method, F func)
        if (isSomeFunction!F && !is(F == RequestHandler)
            && !is(F == NotificationHandler) && !is(F == ResponseHandler))
{
    import dls.util.json : convertFromJSON;

    static if ((Parameters!F).length == 1)
    {
        pushHandler(method, (Nullable!JSONValue params) {
            import dls.util.json : convertToJSON;

            auto arg = convertFromJSON!((Parameters!F)[0])(params.isNull ? JSONValue(null) : params);

            static if (is(ReturnType!F == void))
            {
                func(arg);
            }
            else
            {
                return convertToJSON(func(arg));
            }
        });
    }
    else static if ((Parameters!F).length == 2)
    {
        pushHandler(method, (string id, Nullable!JSONValue params) => func(id,
                convertFromJSON!((Parameters!F)[1])(params.isNull ? JSONValue(null) : params)));
    }
    else
    {
        static assert(false);
    }
}

/++ Registers a new static `RequestHandler`. +/
private void pushHandler(string method, RequestHandler h)
{
    requestHandlers[method] = h;
}

/++ Registers a new static `NotificationHandler`. +/
private void pushHandler(string method, NotificationHandler h)
{
    notificationHandlers[method] = h;
}

/++ Registers a new static `ResponseHandler`. +/
private void pushHandler(string method, ResponseHandler h)
{
    responseHandlers[method] = h;
}

/++ Registers a new dynamic `ResponseHandler` (used at runtime) +/
void pushHandler(string id, string method)
{
    runtimeResponseHandlers[id] = responseHandlers[method];
}

/++
Returns the `RequestHandler`/`NotificationHandler`/`ResponseHandler`
corresponding to a specific LSP method.
+/
T handler(T)(string methodOrId)
        if (is(T == RequestHandler) || is(T == NotificationHandler) || is(T == ResponseHandler))
{
    static if (is(T == RequestHandler))
    {
        alias handlers = requestHandlers;
    }
    else static if (is(T == NotificationHandler))
    {
        alias handlers = notificationHandlers;
    }
    else
    {
        alias handlers = runtimeResponseHandlers;
    }

    if (methodOrId in handlers)
    {
        auto h = handlers[methodOrId];

        static if (is(T == ResponseHandler))
        {
            runtimeResponseHandlers.remove(methodOrId);
        }

        return h;
    }

    throw new HandlerNotFoundException(methodOrId);
}
