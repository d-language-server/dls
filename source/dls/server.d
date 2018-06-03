module dls.server;

import dls.protocol.handlers;
import dls.protocol.jsonrpc;

@safe shared static this()
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
    import dls.protocol.interfaces : InitializeParams;
    import dls.util.logger : logger;
    import std.algorithm : find, findSplit;
    import std.json : JSONValue;
    import std.string : strip, stripRight;
    import std.typecons : Nullable, nullable;

    static bool initialized = false;
    static bool shutdown = false;
    static bool exit = false;
    private static InitializeParams _initState;

    @safe @property static InitializeParams initState()
    {
        return _initState;
    }

    @safe @property static void initState(InitializeParams params)
    {
        _initState = params;

        debug
        {
            logger.trace = InitializeParams.Trace.verbose;
        }
        else
        {
            logger.trace = params.trace;
        }
    }

    @safe @property static InitializeParams.InitializationOptions initOptions()
    {
        return _initState.initializationOptions.isNull
            ? new InitializeParams.InitializationOptions() : _initState.initializationOptions;
    }

    @trusted static void loop()
    {
        import std.conv : to;
        import std.stdio : stdin;

        while (!stdin.eof && !exit)
        {
            string[][] headers;
            string line;

            do
            {
                line = stdin.readln().stripRight();
                auto parts = line.findSplit(":");

                if (parts[1].length > 0)
                {
                    headers ~= [parts[0], parts[2]];
                }
            }
            while (line.length > 0);

            if (headers.length == 0)
            {
                continue;
            }

            auto contentLengthResult = headers.find!((parts,
                    name) => parts.length > 0 && parts[0] == name)("Content-Length");

            if (contentLengthResult.length == 0)
            {
                logger.error("No valid Content-Length section in header");
                continue;
            }

            static char[] buffer;
            const contentLength = contentLengthResult[0][1].strip().to!size_t;
            buffer.length = contentLength;
            const content = stdin.rawRead(buffer);

            handleJSON(content);
        }
    }

    @trusted private static void handleJSON(in char[] content)
    {
        import dls.protocol.jsonrpc : send, sendError;
        import dls.util.json : convertFromJSON;
        import std.algorithm : canFind;
        import std.json : JSONException, parseJSON;

        RequestMessage request;

        try
        {
            const json = parseJSON(content);

            if ("method" in json)
            {
                if ("id" in json)
                {
                    request = convertFromJSON!RequestMessage(json);

                    if (!shutdown && (initialized || ["initialize"].canFind(request.method)))
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

                    if (initialized)
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
            sendError(ErrorCodes.parseError, request, JSONValue(e.message));
        }
        catch (HandlerNotFoundException e)
        {
            logger.errorf("%s: %s", ErrorCodes.methodNotFound[0], e);
            sendError(ErrorCodes.methodNotFound, request, JSONValue(e.message));
        }
        catch (Exception e)
        {
            logger.errorf("%s: %s", ErrorCodes.internalError[0], e);
            sendError(ErrorCodes.internalError, request, JSONValue(e.message));
        }
    }
}
