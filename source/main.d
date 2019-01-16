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
    import dls.info : currentVersion;
    import dls.server : Server;
    import dls.util.communicator : SocketCommunicator, StdioCommunicator, communicator;
    import dls.util.i18n : Tr, tr;
    import std.getopt : defaultGetoptPrinter, getopt;

    bool stdio = true;
    ushort port;
    bool version_;

    //dfmt off
    auto result = getopt(args,
        "stdio",
        tr(Tr.app_help_stdio),
        &stdio,
        "socket|tcp",
        tr(Tr.app_help_socket),
        &port,
        "version",
        tr(Tr.app_help_version),
        &version_);
    //dfmt on

    if (result.helpWanted)
    {
        defaultGetoptPrinter(tr(Tr.app_help_title), result.options);
        return 0;
    }
    else if (version_)
    {
        communicator = new StdioCommunicator();
        communicator.write(currentVersion ~ "\n");
        communicator.flush();
        return 0;
    }
    else if (port > 0)
    {
        communicator = new SocketCommunicator(port);
    }
    else if (stdio)
    {
        communicator = new StdioCommunicator();
    }
    else
    {
        return -1;
    }

    Server.loop();
    return Server.initialized ? 1 : 0;
}
