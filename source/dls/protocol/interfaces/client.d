module dls.protocol.interfaces.client;

public import dls.protocol.definitions;

private abstract class RegistrationBase
{
    string id;
    string method;
}

package interface RegistrationOptionsBase
{
}

class Registration : RegistrationBase
{
    Nullable!RegistrationOptionsBase registerOptions;
}

class TextDocumentRegistrationOptions : RegistrationOptionsBase
{
    Nullable!DocumentSelector documentSelector;
}

class RegistrationParams
{
    Registration[] registrations;
}

class Unregistration : RegistrationBase
{
}

class UnregistrationParams
{
    Unregistration[] unregistrations;
}
