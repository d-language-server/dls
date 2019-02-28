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

int main(string[] args)
{
    import dls.info : buildArch, buildPlatform, buildType, compilerVersion, currentVersion;
    import dls.protocol.interfaces : InitializeParams;
    import dls.protocol.state : initOptions;
    import dls.server : Server;
    import dls.util.communicator : SocketCommunicator, StdioCommunicator, communicator;
    import dls.util.getopt : printHelp;
    import dls.util.i18n : Tr, tr;
    import std.compiler : name;
    import std.conv : text;
    import std.getopt : config, getopt;

    bool stdio = true;
    ushort port;
    bool version_;
    auto init = new InitializeParams.InitializationOptions();

    //dfmt off
    auto result = getopt(args, config.passThrough,
        "stdio",        tr(Tr.app_help_stdio),      &stdio,
        "socket",       tr(Tr.app_help_socket),     &port,
        "tcp",          tr(Tr.app_help_socket),     &port,
        "version",      tr(Tr.app_help_version),    &version_,
        "init.autoUpdate",          &init.autoUpdate,
        "init.preReleaseBuilds",    &init.preReleaseBuilds,
        "init.safeMode",            &init.safeMode,
        "init.catchErrors",         &init.catchErrors,
        "init.logFile",             &init.logFile,
        "init.capabilities.hover",                      &init.capabilities.hover,
        "init.capabilities.completion",                 &init.capabilities.completion,
        "init.capabilities.definition",                 &init.capabilities.definition,
        "init.capabilities.typeDefinition",             &init.capabilities.typeDefinition,
        "init.capabilities.references",                 &init.capabilities.references,
        "init.capabilities.documentHighlight",          &init.capabilities.documentHighlight,
        "init.capabilities.documentSymbol",             &init.capabilities.documentSymbol,
        "init.capabilities.workspaceSymbol",            &init.capabilities.workspaceSymbol,
        "init.capabilities.codeAction",                 &init.capabilities.codeAction,
        "init.capabilities.documentFormatting",         &init.capabilities.documentFormatting,
        "init.capabilities.documentRangeFormatting",    &init.capabilities.documentRangeFormatting,
        "init.capabilities.documentOnTypeFormatting",   &init.capabilities.documentOnTypeFormatting,
        "init.capabilities.rename",                     &init.capabilities.rename,
        "init.symbol.autoImports",  &init.symbol.autoImports);
    //dfmt on

    initOptions = init;

    if (result.helpWanted)
    {
        communicator = new StdioCommunicator(false);
        printHelp(tr(Tr.app_help_title), result.options, data => communicator.write(data));
        communicator.flush();
        return 0;
    }
    else if (version_)
    {
        communicator = new StdioCommunicator(false);
        communicator.write(tr(Tr.app_version_dlsVersion, [currentVersion,
                buildPlatform, buildArch, buildType]));
        communicator.write("\n");
        communicator.write(tr(Tr.app_version_compilerVersion, [name,
                compilerVersion, text(__VERSION__)]));
        communicator.write("\n");
        communicator.flush();
        return 0;
    }
    else if (port > 0)
    {
        communicator = new SocketCommunicator(port);
    }
    else if (stdio)
    {
        communicator = new StdioCommunicator(true);
    }
    else
    {
        return -1;
    }

    Server.loop();
    return Server.initialized ? 1 : 0;
}
