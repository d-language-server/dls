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

module dls.server;

shared static this()
{
    import dls.protocol.handlers : isHandler, pushHandler;
    import dls.util.setup : initialSetup;
    import std.algorithm : map;
    import std.array : join, split;
    import std.meta : AliasSeq;
    import std.traits : hasUDA, select;
    import std.typecons : tuple;
    import std.string : capitalize;

    initialSetup();

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

final abstract class Server
{
    import dls.protocol.interfaces : InitializeParams;

    static bool initialized;
    static bool exit;

    static void loop()
    {
        import dls.util.communicator : communicator;
        import dls.util.logger : logger;
        import std.algorithm : findSplit;
        import std.array : appender;
        import std.conv : to;
        import std.string : strip, stripRight;

        auto lineAppender = appender!(char[]);
        string[string] headers;
        string line;

        while (communicator.hasData() && !exit)
        {
            headers.clear();

            do
            {
                bool cr;
                bool lf;

                lineAppender.clear();

                do
                {
                    auto res = communicator.read(1);

                    if (res.length == 0)
                    {
                        break;
                    }

                    lineAppender ~= res[0];

                    if (cr)
                    {
                        lf = res[0] == '\n';
                    }

                    cr = res[0] == '\r';
                }
                while (!lf);

                line = lineAppender.data.stripRight().to!string;
                auto parts = line.findSplit(":");

                if (parts[1].length > 0)
                {
                    headers[parts[0]] = parts[2];
                }
            }
            while (line.length > 0);

            if (headers.length == 0)
            {
                continue;
            }

            if ("Content-Length" !in headers)
            {
                logger.error("No valid Content-Length section in header");
                continue;
            }

            handleJSON(communicator.read(headers["Content-Length"].strip().to!size_t));
        }
    }

    private static void handleJSON(in char[] content)
    {
        import dls.protocol.handlers : HandlerNotFoundException,
            NotificationHandler, RequestHandler, ResponseHandler, handler;
        import dls.protocol.jsonrpc : ErrorCodes, InvalidParamsException,
            NotificationMessage, RequestMessage, ResponseMessage, send, sendError;
        import dls.protocol.state : initOptions;
        import dls.util.json : convertFromJSON;
        import dls.util.logger : logger;
        import std.algorithm : among, startsWith;
        import std.json : JSONException, JSONValue, parseJSON;

        RequestMessage request;
        NotificationMessage notification;

        void findAndExecuteHandler()
        {
            try
            {
                const json = parseJSON(content);

                if ("method" in json)
                {
                    if ("id" in json)
                    {
                        request = convertFromJSON!RequestMessage(json);

                        if (initialized || request.method.among("initialize", "shutdown"))
                        {
                            send(request.id,
                                    handler!RequestHandler(request.method)(request.params));
                        }
                        else
                        {
                            sendError(ErrorCodes.serverNotInitialized, request, JSONValue());
                        }
                    }
                    else
                    {
                        notification = convertFromJSON!NotificationMessage(json);

                        if (initialized || notification.method == "exit")
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
                logger.errorf("%s: %s", ErrorCodes.parseError[0], e.toString());
                sendError(ErrorCodes.parseError, request, JSONValue(e.toString()));
            }
            catch (HandlerNotFoundException e)
            {
                if (notification is null || !notification.method.startsWith("$/"))
                {
                    logger.errorf("%s: %s", ErrorCodes.methodNotFound[0], e.toString());
                    sendError(ErrorCodes.methodNotFound, request, JSONValue(e.toString()));
                }
            }
            catch (InvalidParamsException e)
            {
                logger.errorf("%s: %s", ErrorCodes.invalidParams[0], e.toString());
                sendError(ErrorCodes.invalidParams, request, JSONValue(e.toString()));
            }
            catch (Exception e)
            {
                logger.errorf("%s: %s", ErrorCodes.internalError[0], e.toString());
                sendError(ErrorCodes.internalError, request, JSONValue(e.toString()));
            }
        }

        if (initOptions.catchErrors)
        {
            try
            {
                findAndExecuteHandler();
            }
            catch (Error e)
            {
                logger.errorf("%s: %s", ErrorCodes.internalError[0], e.toString());
                sendError(ErrorCodes.internalError, request, JSONValue(e.toString()));
            }
        }
        else
        {
            findAndExecuteHandler();
        }
    }
}
