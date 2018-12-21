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

module dls.protocol.interfaces.client;

private abstract class RegistrationBase
{
    string id;
    string method;

    @safe this(string id, string method) pure nothrow
    {
        this.id = id;
        this.method = method;
    }
}

package interface RegistrationOptions
{
}

final class Registration(R : RegistrationOptions) : RegistrationBase
{
    import std.typecons : Nullable;

    Nullable!R registerOptions;

    @safe this(string id = string.init, string method = string.init,
            Nullable!R registerOptions = Nullable!R.init) pure nothrow
    {
        super(id, method);
        this.registerOptions = registerOptions;
    }
}

class TextDocumentRegistrationOptions : RegistrationOptions
{
    import dls.protocol.definitions : DocumentSelector;
    import std.typecons : Nullable;

    Nullable!DocumentSelector documentSelector;

    @safe this(Nullable!DocumentSelector documentSelector = Nullable!DocumentSelector.init) pure nothrow
    {
        this.documentSelector = documentSelector;
    }
}

final class RegistrationParams(R : RegistrationOptions)
{
    Registration!R[] registrations;

    @safe this(Registration!R[] registrations = Registration!R[].init) pure nothrow
    {
        this.registrations = registrations;
    }
}

final class Unregistration : RegistrationBase
{
    @safe this(string id = string.init, string method = string.init) pure nothrow
    {
        super(id, method);
    }
}

final class UnregistrationParams
{
    Unregistration[] unregistrations;

    @safe this(Unregistration[] unregistrations = Unregistration[].init) pure nothrow
    {
        this.unregistrations = unregistrations;
    }
}
