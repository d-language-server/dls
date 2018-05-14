module dls.server;

import dls.protocol.handlers;
import dls.protocol.jsonrpc;

shared static this()
{
    import std.algorithm : map;
    import std.array : join, split;
    import std.meta : AliasSeq;
    import std.traits : hasUDA, select;
    import std.typecons : tuple;
    import std.string : capitalize;

    foreach (modName; AliasSeq!("general", "client", "text_document", "window", "workspace"))
    {
        mixin("import dls.protocol.messages" ~ (modName.length ? "." ~ modName : "") ~ ";");
        mixin("alias mod = dls.protocol.messages" ~ (modName.length ? "." ~ modName : "") ~ ";");

        foreach (thing; __traits(allMembers, mod))
        {
            mixin("alias t = " ~ thing ~ ";");

            static if (isHandler!t)
            {
                enum attrs = tuple(__traits(getAttributes, t));
                enum attrsWithDefaults = tuple(modName[0] ~ modName.split('_')
                            .map!capitalize().join()[1 .. $], thing, attrs.expand);
                enum parts = tuple(attrsWithDefaults[attrs.length > 0 ? 2 : 0],
                            attrsWithDefaults[attrs.length > 1 ? 3 : 1]);
                enum method = select!(parts[0].length != 0)(parts[0] ~ "/", "") ~ parts[1];

                pushHandler(method, &t);
            }
        }
    }
}

abstract class Server
{

    import logger = std.experimental.logger;
    import dls.protocol.interfaces : InitializeParams;
    import std.algorithm : find, findSplit;
    import std.json : JSONValue;
    import std.string : strip, stripRight;
    import std.typecons : Nullable, nullable;

    private static bool _initialized = false;
    private static bool _shutdown = false;
    private static bool _exit = false;
    private static InitializeParams _initState;

    @property static InitializeParams initState()
    {
        return _initState;
    }

    @property static void initState(InitializeParams params)
    {
        _initState = params;

        debug
        {
            logger.globalLogLevel = logger.LogLevel.all;
        }
        else
        {
            //dfmt off
            immutable map = [
                InitializeParams.Trace.off : logger.LogLevel.off,
                InitializeParams.Trace.messages : logger.LogLevel.info,
                InitializeParams.Trace.verbose : logger.LogLevel.all
            ];
            //dfmt on
            logger.globalLogLevel = params.trace.isNull ? logger.LogLevel.off : map[params.trace];
        }
    }

    @property static void opDispatch(string name, T)(T arg)
    {
        mixin("_" ~ name ~ " = arg;");
    }

    static void loop()
    {
        import std.conv : to;
        import std.stdio : stdin;

        while (!stdin.eof && !_exit)
        {
            string[][] headers;
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
                logger.error("No valid Content-Length section in header");
                continue;
            }

            static char[] buffer;
            immutable contentLength = contentLengthResult[0][1].strip().to!size_t;
            buffer.length = contentLength;
            immutable content = stdin.rawRead(buffer).idup;
            // TODO: support UTF-16/32 according to Content-Type when it's supported

            handleJSON(content);
        }
    }

    private static void handleJSON(T)(immutable(T[]) content)
    {
        import dls.util.json : convertFromJSON;
        import std.algorithm : canFind;
        import std.json : JSONException, parseJSON;

        RequestMessage request;

        try
        {
            immutable json = parseJSON(content);

            if ("method" in json)
            {
                if ("id" in json)
                {
                    request = convertFromJSON!RequestMessage(json);

                    if (!_shutdown && (_initialized || ["initialize"].canFind(request.method)))
                    {
                        send(request.id, handler!RequestHandler(request.method)(request.params));
                    }
                    else
                    {
                        sendError(ErrorCodes.serverNotInitialized, request, JSONValue());
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

                if (response.error.isNull)
                {
                    handler!ResponseHandler(response.id.str)(response.id.str, response.result);
                }
                else
                {
                    logger.error(response.error.message);
                }
            }
        }
        catch (JSONException e)
        {
            logger.errorf("%s: %s", ErrorCodes.parseError[0], e);
            sendError(ErrorCodes.parseError, request, JSONValue(e.toString()));
        }
        catch (HandlerNotFoundException e)
        {
            logger.errorf("%s: %s", ErrorCodes.methodNotFound[0], e);
            sendError(ErrorCodes.methodNotFound, request, JSONValue(e.toString()));
        }
        catch (Exception e)
        {
            logger.errorf("%s: %s", ErrorCodes.internalError[0], e);
            sendError(ErrorCodes.internalError, request, JSONValue(e.toString()));
        }
    }

    private static void sendError(ErrorCodes error, RequestMessage request, JSONValue data)
    {
        if (request !is null)
        {
            send(request.id, Nullable!JSONValue(), ResponseError.fromErrorCode(error, data).nullable);
        }
    }

    /++ Sends a request or a notification message. +/
    static string send(string method, Nullable!JSONValue params)
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

    static string send(T)(string method, T params) if (!is(T : Nullable!JSONValue))
    {
        import dls.util.json : convertToJSON;

        return send(method, convertToJSON(params).nullable);
    }

    /++ Sends a response message. +/
    private static void send(JSONValue id, Nullable!JSONValue result,
            Nullable!ResponseError error = Nullable!ResponseError())
    {
        send!ResponseMessage(id, null, result, error);
    }

    private static void send(T : Message)(JSONValue id, string method,
            Nullable!JSONValue payload, Nullable!ResponseError error)
    {
        import dls.protocol.jsonrpc : send;
        import std.meta : AliasSeq;
        import std.traits : select;

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

        send(message);
    }
}
