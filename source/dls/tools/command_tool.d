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

module dls.tools.command_tool;

import dls.tools.tool : Tool;

enum Commands : string
{
    codeAction_analysis_disableCheck = "codeAction.analylis.disableCheck"
}

class CommandTool : Tool
{
    import std.json : JSONValue;

    private static CommandTool _instance;

    static void initialize()
    {
        _instance = new CommandTool();
    }

    static void shutdown()
    {
        destroy(_instance);
    }

    @property static CommandTool instance()
    {
        return _instance;
    }

    @property string[] commands()
    {
        return [Commands.codeAction_analysis_disableCheck];
    }

    JSONValue executeCommand(in string command, in JSONValue[] arguments)
    {
        import dls.protocol.jsonrpc : InvalidParamsException;
        import dls.tools.analysis_tool : AnalysisTool;
        import dls.util.logger : logger;
        import dls.util.uri : Uri;
        import std.format : format;

        logger.infof("Executing command %s with arguments %s", command, arguments);

        switch (command)
        {
        case Commands.codeAction_analysis_disableCheck:
            AnalysisTool.instance.disableCheck(new Uri(arguments[0].str), arguments[1].str);
            break;

        default:
            throw new InvalidParamsException(format!"unknown command: %s"(command));
        }

        return JSONValue(null);
    }
}
