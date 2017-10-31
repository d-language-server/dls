module dls.protocol.interfaces.client;

public import dls.protocol.definitions;

private abstract class RegistrationBase
{
    string id;
    string method;
}

class Registration : RegistrationBase
{
    Nullable!JSONValue registerOptions;
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
