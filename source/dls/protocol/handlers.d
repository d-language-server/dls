module dls.protocol.handlers;

import std.json : JSONValue;
import std.typecons : Nullable;
import std.traits;

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
Checks if a method has a handler registered for it. Used to determine if the
server should send a request or a notification to the client (if the method has
a handler, then the server will expect a response and thus send a request).
+/
bool hasRegisteredHandler(string method)
{
    return (method in requestHandlers) || (method in notificationHandlers)
        || (method in responseHandlers);
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
