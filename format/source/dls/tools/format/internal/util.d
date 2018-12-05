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

module dls.tools.format.internal.util;

import dparse.lexer : Token;

struct RollbackRange(T)
{
    T[] data;
    Memento!size_t index;

    @property T current()
    {
        assert(index >= 0);
        assert(index < data.length);
        return data[index];
    }

    alias data this;
}

struct Memento(T)
{
    import std.container : SList;

    T data;
    private SList!T saved;

    void save()
    {
        saved.insertFront(data);
    }

    void clear()
    {
        saved.removeFront();
    }

    void load()
    {
        data = saved.front;
        clear();
    }

    alias data this;
}

string tokenString(const Token token)
{
    import dparse.lexer : str;

    return token.text.length > 0 ? token.text : str(token.type);
}
