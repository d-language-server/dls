module protocol.handlers;

import protocol.jsonrpc;
public import std.json;
import std.traits;
public import std.typecons;

alias RequestHandler = ResponseData function(Nullable!JSONValue);
alias NotificationHandler = void function(Nullable!JSONValue);
alias ResponseHandler = void function(Nullable!JSONValue, Nullable!ResponseError);

private shared(RequestHandler[string]) requesthandlers;
private shared(NotificationHandler[string]) notificationHandlers;
private shared(ResponseHandler[string]) responseHandler;

/++
Checks if a function is a `RequestHandler` or a `NotificationHandler`.
They should only be registered at startup time and will never be unregistered.
+/
template isStaticHandler(T...)
{
    enum isStaticHandler = __traits(compiles, isSomeFunction!T) && isSomeFunction!T
            && (is(FunctionTypeOf!T == FunctionTypeOf!RequestHandler)
                    || is(FunctionTypeOf!T == FunctionTypeOf!NotificationHandler));
}

/++ Stores data to respond to a request: +/
struct ResponseData
{
    Nullable!JSONValue result = JSONValue(null);
    Nullable!ResponseError error;

    this(JSONValue res)
    {
        this.result = res.nullable;
    }

    this(ResponseError err)
    {
        this.error = err.nullable;
    }
}

class HandlerNotFoundException : Exception
{
    this(string method)
    {
        super("No handler found for methodd " ~ method);
    }
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
    responseHandler[id.toString()] = h;
}

/++
Returns the `RequestHandler`/`NotificationHandler` corresponding to `method`.
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
    auto h = responseHandler[idString];

    responseHandler.remove(idString);
    return h;
}
