import protocol.handlers;
import protocol.interfaces;
import protocol.jsonrpc;
import std.algorithm;
import std.conv;
import std.meta;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import util.json;

shared static this()
{
    foreach (modname; AliasSeq!("general", "client", "text_document", "window", "workspace"))
    {
        mixin("alias mod = protocol.messages" ~ (modname.length ? "." ~ modname : "") ~ ";");
        mixin("import protocol.messages" ~ (modname.length ? "." ~ modname : "") ~ ";");

        foreach (thing; __traits(allMembers, mod))
        {
            mixin("alias t = " ~ thing ~ ";");

            static if (isStaticHandler!t)
            {
                enum attrs = tuple(__traits(getAttributes, t));
                enum attrsWithDefaults = tuple(modname[0] ~ modname.split('_')
                            .map!capitalize().join()[1 .. $], thing, attrs.expand);
                enum parts = tuple(attrsWithDefaults[attrs.length > 0 ? 2 : 0],
                            attrsWithDefaults[attrs.length > 1 ? 3 : 1]);
                pushHandler(select!(parts[0].length != 0)(parts[0] ~ "/", "") ~ parts[1], &t);
            }
        }
    }
}

class Server
{
    static private shared(bool) _initialized = false;
    static private shared(bool) _shutdown = false;
    static private shared(bool) _exit = false;
    static shared(InitializeParams) _initState;

    @property static opDispatch(string name, T)(T arg)
    {
        mixin("_" ~ name ~ "= arg;");
    }

    static void loop()
    {
        debug stderr.writeln("Server starting");

        while (!stdin.eof && !_exit)
        {
            string[][] headers = [];
            string line;

            do
            {
                line = stdin.readln().stripRight();
                auto parts = line.findSplit(":");

                if (parts[1].length)
                {
                    headers ~= [parts[0], parts[2]];
                }
            }
            while (line.length);

            if (headers.length == 0)
            {
                continue;
            }

            auto contentLengthResult = headers.find!((parts,
                    name) => parts.length && parts[0] == name)("Content-Length");

            if (contentLengthResult.length == 0)
            {
                stderr.writeln(new Exception("No valid Content-Length section in header"));
                continue;
            }

            immutable contentLength = contentLengthResult[0][1].strip().to!size_t;
            immutable content = stdin.rawRead(new char[contentLength]).idup;
            // TODO: support UTF-16/32 according to Content-Type when it's supported

            import std.concurrency : spawn;

            spawn(&(handleJSON!char), content);
        }

        debug stderr.writeln("Server stopping");
    }

    static void handleJSON(T)(immutable(T[]) content)
    {
        RequestMessage request;

        try
        {
            immutable json = parseJSON(content);

            if ("method" in json)
            {
                if ("id" in json)
                {
                    request = convertFromJSON!RequestMessage(json);

                    if (!_shutdown && (_initialized || request.method == "initialize"))
                    {
                        auto resAndErr = handler!RequestHandler(request.method)(request.params);
                        send(request.id, resAndErr.result, resAndErr.error);
                    }
                    else
                    {
                        send(request.id, JSONValue().nullable,
                                ResponseError.fromErrorCode(ErrorCodes.serverNotInitialized));
                    }
                }
                else
                {
                    auto notification = convertFromJSON!NotificationMessage(json);

                    if (_initialized)
                    {
                        handler!NotificationHandler(notification.method)(notification.params);
                    }
                }
            }
            else
            {
                auto response = convertFromJSON!ResponseMessage(json);
                handler(response.id)(response.result, response.error);
            }
        }
        catch (JSONException e)
        {
            sendError!(ErrorCodes.parseError)(request);
        }
        catch (HandlerNotFoundException e)
        {
            sendError!(ErrorCodes.methodNotFound)(request);
        }
    }

    static void sendError(ErrorCodes error)(RequestMessage request)
    {
        if (request !is null)
        {
            send(request.id, Nullable!JSONValue(), ResponseError.fromErrorCode(error));
        }
    }

    /++ Sends a request message. +/
    static void send(JSONValue id, string method, Nullable!JSONValue params = Nullable!JSONValue())
    {
        send!RequestMessage(id, method, params, Nullable!ResponseError());
    }

    /++ Sends a response message. +/
    static void send(JSONValue id, Nullable!JSONValue result,
            Nullable!ResponseError error = Nullable!ResponseError())
    {
        send!ResponseMessage(id, null, result, error);
    }

    /++ Sends a notification message. +/
    static void send(string method, Nullable!JSONValue params)
    {
        send!NotificationMessage(JSONValue(), method, params, Nullable!ResponseError());
    }

    private static void send(T : Message)(JSONValue id, string method,
            Nullable!JSONValue payload, Nullable!ResponseError error)
    {
        auto message = new T();

        __traits(getMember, message, select!(__traits(hasMember, T,
                "params"))("params", "result")) = payload;

        foreach (member; AliasSeq!("id", "method", "error"))
        {
            static if (__traits(hasMember, T, member))
            {
                mixin("message." ~ member ~ " = " ~ member ~ ";");
            }
        }

        protocol.jsonrpc.send(message);
    }
}
