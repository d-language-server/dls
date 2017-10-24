module protocol.interfaces.client;

public import protocol.definitions;

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
