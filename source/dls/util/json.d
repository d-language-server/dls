module dls.util.json;

import std.algorithm;
import std.array;
import std.conv;
import std.json;
import std.traits;
import std.typecons;

/++
Converts a `JSONValue` to an object of type `T` by filling its fields with the JSON's fields.
+/
T convertFromJSON(T)(JSONValue json) if (is(T == class) || is(T == struct))
{
    static if (is(T == class))
    {
        auto result = new T();
    }
    else static if (is(T == struct))
    {
        auto result = T();
    }
    else
    {
        static assert(false, "Cannot convert JSON to " ~ typeid(T));
    }

    foreach (member; __traits(allMembers, T))
    {
        static if (__traits(getProtection, __traits(getMember, T,
                member)) == "public" && !isType!(__traits(getMember, T,
                member)) && !isSomeFunction!(__traits(getMember, T, member)))
        {
            try
            {
                __traits(getMember, result, member) = convertFromJSON!(typeof(__traits(getMember,
                        result, member)))(json[normalizeMemberName(member)]);
            }
            catch (JSONException e)
            {
            }
        }
    }

    return result;
}

N convertFromJSON(N : Nullable!T, T)(JSONValue json)
{
    return (json.type == JSON_TYPE.NULL) ? N() : convertFromJSON!T(json).nullable;
}

T convertFromJSON(T : JSONValue)(JSONValue json)
{
    return json.nullable;
}

T convertFromJSON(T)(JSONValue json) if (isNumeric!T)
{
    switch (json.type)
    {
    case JSON_TYPE.INTEGER:
        return json.integer.to!T;

    case JSON_TYPE.UINTEGER:
        return json.uinteger.to!T;

    case JSON_TYPE.FLOAT:
        return json.floating.to!T;

    default:
        throw new JSONException("JSONValue is not a numeric type");
    }
}

T convertFromJSON(T)(JSONValue json) if (isBoolean!T)
{
    switch (json.type)
    {
    case JSON_TYPE.FALSE:
        return false;

    case JSON_TYPE.TRUE:
        return true;

    default:
        throw new JSONException("JSONValue is not a boolean type");
    }
}

T convertFromJSON(T)(JSONValue json) if (isSomeString!T)
{
    return json.str.to!T;
}

T convertFromJSON(T : U[], U)(JSONValue json) if (isArray!T && !isSomeString!T)
{
    return json.array.map!(value => convertFromJSON!U(value)).array;
}

T convertFromJSON(T : U[string], U)(JSONValue json) if (isAssociativeArray!T)
{
    U[string] result;

    foreach (string key, value; json)
    {
        result[key] = convertFromJSON!U(value);
    }

    return result;
}

Nullable!JSONValue convertToJSON(T)(T value)
        if ((is(T == class) || is(T == struct)) && !is(T == JSONValue))
{
    if (value is null)
    {
        return Nullable!JSONValue();
    }

    auto result = JSONValue();

    foreach (member; __traits(allMembers, T))
    {
        static if (__traits(getProtection, __traits(getMember, T,
                member)) == "public" && !isType!(__traits(getMember, T,
                member)) && !isSomeFunction!(__traits(getMember, T, member)))
        {
            auto json = convertToJSON!(typeof(__traits(getMember, value, member)))(
                    __traits(getMember, value, member));

            if (!json.isNull)
            {
                result[normalizeMemberName(member)] = json.get();
            }
        }
    }

    return result.nullable;
}

Nullable!JSONValue convertToJSON(N : Nullable!T, T)(N value)
{
    return value.isNull ? Nullable!JSONValue() : convertToJSON!T(value.get());
}

Nullable!JSONValue convertToJSON(T)(T value) if (is(T == JSONValue))
{
    return value.nullable;
}

Nullable!JSONValue convertToJSON(T)(T value)
        if (isNumeric!T || isBoolean!T || isSomeString!T)
{
    return JSONValue(value).nullable;
}

Nullable!JSONValue convertToJSON(T : U[], U)(T value)
        if (isArray!T && !isSomeString!T)
{
    return JSONValue(value.map!((item) => convertToJSON(item))()
            .map!((json) => json.isNull ? JSONValue(null) : json.get())().array).nullable;
}

Nullable!JSONValue convertToJSON(T : U[string], U)(T value)
        if (isAssociativeArray!T)
{
    auto result = JSONValue();

    foreach (key; value.keys)
    {
        auto json = convertToJSON(value[key]);

        if (json.isNull())
        {
            result[key] = null;
        }
        else
        {
            result[key] = json.get();
        }
    }

    return result.nullable;
}

/++
Removes underscores from names. Some protocol variable names can be reserved names (like `version`) and thus have an
added underscore in their protocol definition.
+/
private auto normalizeMemberName(string name)
{
    import std.string : endsWith;

    return name.endsWith('_') ? name[0 .. $ - 1] : name;
}
