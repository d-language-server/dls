module dls.protocol.interfaces.client;

public import dls.protocol.definitions;

private abstract class RegistrationBase
{
    string id;
    string method;
}

package abstract class RegistrationOptionsBase
{
}

class Registration(R : RegistrationOptionsBase) : RegistrationBase
{
    Nullable!R registerOptions;
}

class TextDocumentRegistrationOptions : RegistrationOptionsBase
{
    Nullable!DocumentSelector documentSelector;
}

class RegistrationParams(R)
{
    Registration!R[] registrations;
}

class Unregistration : RegistrationBase
{
}

class UnregistrationParams
{
    Unregistration[] unregistrations;
}
