module dls.protocol.handlers;

import dls.protocol.jsonrpc;
import dls.util.json;
public import std.json;
import std.traits;
public import std.typecons;

alias RequestHandler = Nullable!JSONValue delegate(Nullable!JSONValue);
alias NotificationHandler = void delegate(Nullable!JSONValue);
alias ResponseHandler = void delegate(Nullable!JSONValue);

private RequestHandler[string] requesthandlers;
private NotificationHandler[string] notificationHandlers;
private ResponseHandler[string] responseHandlers;

enum serverRequest;

/++
Checks if a function is a `RequestHandler` or a `NotificationHandler`.
They should only be registered at startup time and will never be unregistered.
+/
template isStaticHandler(func...)
{
    enum isStaticHandler = __traits(compiles, isSomeFunction!func)
            && isSomeFunction!func && !hasUDA!(func, serverRequest);
}

class HandlerNotFoundException : Exception
{
    this(string method)
    {
        super("No handler found for method " ~ method);
    }
}

/++
Registers a new handler of any kind (`RequestHandler`, `NotificationHandler` or
`ResponseHandler`).
+/
void pushHandler(T, F)(T methodOrId, F func)
        if ((is(T : string) || is(T : JSONValue)) && isSomeFunction!F
            && !is(F == RequestHandler) && !is(F == NotificationHandler)
            && !is(F == ResponseHandler))
{
    pushHandler(methodOrId, (Nullable!JSONValue params) {
        static if ((Parameters!F).length == 0)
        {
            enum args = tuple().expand;
        }
        else
        {
            auto args = convertFromJSON!((Parameters!F)[0])(params);
        }

        static if (is(ReturnType!F == void))
        {
            func(args);
        }
        else
        {
            return convertToJSON(func(args));
        }
    });
}

/++ Registers a new `RequestHandler`. +/
void pushHandler(string method, RequestHandler h)
{
    requesthandlers[method] = h;
}

/++ Registers a new `NotificationHandler`. +/
void pushHandler(string method, NotificationHandler h)
{
    notificationHandlers[method] = h;
}

/++ Registers a new `ResponseHandler`. +/
void pushHandler(JSONValue id, ResponseHandler h)
{
    responseHandlers[id.toString()] = h;
}

/++
Returns the `RequestHandler`/`NotificationHandler` corresponding to a specific
LSP method.
+/
auto handler(T)(string method)
{
    static if (is(T : RequestHandler))
    {
        alias handlers = requesthandlers;
    }
    else static if (is(T : NotificationHandler))
    {
        alias handlers = notificationHandlers;
    }
    else
    {
        static assert(false);
    }

    if (method in handlers)
    {
        return handlers[method];
    }

    throw new HandlerNotFoundException(method);
}

/++
Returns the `ResponseHandler` corresponding to `id` and unregisters it.
`ResponseHandler`s are registered dynamically and should never be used more
than once.
+/
auto handler(JSONValue id)
{
    auto idString = id.toString();
    auto h = responseHandlers[idString];

    responseHandlers.remove(idString);
    return h;
}
