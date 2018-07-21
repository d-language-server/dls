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

    private this(string id, string method)
    {
        this.id = id;
        this.method = method;
    }
}

package interface RegistrationOptionsBase
{
}

class Registration(R : RegistrationOptionsBase) : RegistrationBase
{
    import std.typecons : Nullable;

    Nullable!R registerOptions;

    this(string id = string.init, string method = string.init,
            Nullable!R registerOptions = Nullable!R.init)
    {
        super(id, method);
        this.registerOptions = registerOptions;
    }
}

class TextDocumentRegistrationOptions : RegistrationOptionsBase
{
    import dls.protocol.definitions : DocumentSelector;
    import std.typecons : Nullable;

    Nullable!DocumentSelector documentSelector;

    this(Nullable!DocumentSelector documentSelector = Nullable!DocumentSelector.init)
    {
        this.documentSelector = documentSelector;
    }
}

class RegistrationParams(R)
{
    Registration!R[] registrations;

    this(Registration!R[] registrations = Registration!R[].init)
    {
        this.registrations = registrations;
    }
}

class Unregistration : RegistrationBase
{
    this(string id = string.init, string method = string.init)
    {
        super(id, method);
    }
}

class UnregistrationParams
{
    Unregistration[] unregistrations;

    this(Unregistration[] unregistrations = Unregistration[].init)
    {
        this.unregistrations = unregistrations;
    }
}
