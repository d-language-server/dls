module dls.protocol.interfaces.client;

import std.typecons : Nullable;

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

package abstract class RegistrationOptionsBase
{
}

class Registration(R : RegistrationOptionsBase) : RegistrationBase
{
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
