module dls.protocol.handlers;

import dls.protocol.jsonrpc;
import dls.util.json;
public import std.json;
import std.traits;
public import std.typecons;

alias RequestHandler = Nullable!JSONValue delegate(Nullable!JSONValue);
alias NotificationHandler = void delegate(Nullable!JSONValue);
alias ResponseHandler = void delegate(Nullable!JSONValue);

private RequestHandler[string] requestHandlers;
private NotificationHandler[string] notificationHandlers;
private ResponseHandler[string] responseHandlers;
private ResponseHandler[string] runtimeResponseHandlers;

enum ServerRequest;

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
Checks if a method has a handler registered for it. Used to determine if the
server should send a request or a notification to the client (if the method has
a handler, then the server will expect a response and thus send a request).
+/
bool hasRegisterHandler(string method)
{
    return (method in requestHandlers) || (method in notificationHandlers)
        || (method in responseHandlers);
}

/++
Registers a new handler of any kind (`RequestHandler`, `NotificationHandler` or
`ResponseHandler`).
+/
void pushHandler(bool serverRequest, F)(string method, F func)
        if (isSomeFunction!F && !is(F == RequestHandler)
            && !is(F == NotificationHandler) && !is(F == ResponseHandler))
{
    static if (!is(ReturnType!F == void))
    {
        const pusher = &pushRequestHandler;
    }
    else static if (serverRequest)
    {
        const pusher = &pushResponseHandler;
    }
    else
    {
        const pusher = &pushNotificationHandler;
    }

    pusher(method, (Nullable!JSONValue params) {
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

/++ Registers a new static `RequestHandler`. +/
private void pushRequestHandler(string method, RequestHandler h)
{
    requestHandlers[method] = h;
}

/++ Registers a new static `NotificationHandler`. +/
private void pushNotificationHandler(string method, NotificationHandler h)
{
    notificationHandlers[method] = h;
}

/++ Registers a new static `ResponseHandler`. +/
private void pushResponseHandler(string method, ResponseHandler h)
{
    responseHandlers[method] = h;
}

/++ Registers a new dynamic `ResponseHandler` (used at runtime) +/
void pushHandler(JSONValue id, string method)
{
    runtimeResponseHandlers[id.str] = responseHandlers[method];
}

/++
Returns the `RequestHandler`/`NotificationHandler` corresponding to a specific
LSP method.
+/
auto handler(T)(string method)
{
    static if (is(T : RequestHandler))
    {
        alias handlers = requestHandlers;
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
Returns the `ResponseHandler` corresponding to `id` and unregisters it. Runtime
`ResponseHandler`s are registered dynamically and will never be used more than
once, as the id should always be unique.
+/
auto handler(JSONValue id)
{
    auto h = runtimeResponseHandlers[id.str];
    runtimeResponseHandlers.remove(id.str);
    return h;
}
