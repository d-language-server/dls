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

module dls.protocol.interfaces.window;

class ShowMessageParams
{
    MessageType type;
    string message;

    this(MessageType type = MessageType.init, string message = string.init)
    {
        this.type = type;
        this.message = message;
    }
}

enum MessageType : uint
{
    error = 1,
    warning = 2,
    info = 3,
    log = 4
}

class ShowMessageRequestParams : ShowMessageParams
{
    import std.typecons : Nullable;

    Nullable!(MessageActionItem[]) actions;

    this(MessageType type = MessageType.init, string message = string.init,
            Nullable!(MessageActionItem[]) actions = Nullable!(MessageActionItem[]).init)
    {
        super(type, message);
        this.actions = actions;
    }
}

class MessageActionItem
{
    string title;

    this(string title = string.init)
    {
        this.title = title;
    }
}

alias LogMessageParams = ShowMessageParams;
