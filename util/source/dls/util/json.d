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

module dls.util.json;

import std.json : JSONValue;
import std.traits : isArray, isAssociativeArray, isBoolean, isNumeric, isSomeChar, isSomeString;
import std.typecons : Nullable;

/++
Converts a `JSONValue` to an object of type `T` by filling its fields with the JSON's fields.
+/
T convertFromJSON(T)(JSONValue json) if (is(T == class) || is(T == struct))
{
    import std.json : JSONException, JSON_TYPE;
    import std.meta : Alias;
    import std.traits : isSomeFunction, isType;

    static if (is(T == class))
    {
        auto result = new T();
    }
    else
    {
        auto result = T();
    }

    if (json.type != JSON_TYPE.OBJECT)
    {
        throw new JSONException(json.toString() ~ " is not an object type");
    }

    foreach (member; __traits(allMembers, T))
    {
        alias m = Alias!(__traits(getMember, T, member));

        static if (__traits(getProtection, m) == "public" && !isType!(m) && !isSomeFunction!(m))
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

T convertFromJSON(T)(JSONValue json) if (is(T == interface))
{
    static assert(false, "Cannot instantiate an interface");
}

version (unittest)
{
    struct TestStruct
    {
        uint uinteger;
        JSONValue json;
    }

    class TestClass
    {
        int integer;
        float floating;
        string text;
        int[] array;
        string[string] dictionary;
        TestStruct testStruct;
    }
}

unittest
{
    import std.json : parseJSON;

    const jsonString = `{
        "integer": 42,
        "floating": 3.0,
        "text": "Hello world",
        "array": [0, 1, 2],
        "dictionary": {
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        },
        "testStruct": {
            "uinteger": 16,
            "json": {
                "key": "value"
            }
        }
    }`;

    const testClass = convertFromJSON!TestClass(parseJSON(jsonString));
    assert(testClass.integer == 42);
    assert(testClass.floating == 3.0);
    assert(testClass.text == "Hello world");
    assert(testClass.array == [0, 1, 2]);
    const dictionary = ["key1" : "value1", "key2" : "value2", "key3" : "value3"];
    assert(testClass.dictionary == dictionary);
    assert(testClass.testStruct.uinteger == 16);
    assert(testClass.testStruct.json["key"].str == "value");
}

N convertFromJSON(N : Nullable!T, T)(JSONValue json)
{
    import std.json : JSON_TYPE;
    import std.typecons : nullable;

    return (json.type == JSON_TYPE.NULL) ? N() : convertFromJSON!T(json).nullable;
}

unittest
{
    auto json = JSONValue(42);
    auto result = convertFromJSON!(Nullable!int)(json);
    assert(!result.isNull && result.get() == json.integer);

    json = JSONValue(null);
    assert(convertFromJSON!(Nullable!int)(json).isNull);
}

T convertFromJSON(T : JSONValue)(JSONValue json)
{
    import std.typecons : nullable;

    return json.nullable;
}

unittest
{
    assert(convertFromJSON!JSONValue(JSONValue(42)) == JSONValue(42));
}

T convertFromJSON(T)(JSONValue json) if (isNumeric!T || isSomeChar!T)
{
    import std.conv : to;
    import std.json : JSONException, JSON_TYPE;

    switch (json.type)
    {
    case JSON_TYPE.NULL, JSON_TYPE.FALSE:
        return 0.to!T;

    case JSON_TYPE.TRUE:
        return 1.to!T;

    case JSON_TYPE.FLOAT:
        return json.floating.to!T;

    case JSON_TYPE.INTEGER:
        return json.integer.to!T;

    case JSON_TYPE.UINTEGER:
        return json.uinteger.to!T;

    case JSON_TYPE.STRING:
        return json.str.to!T;

    default:
        throw new JSONException(json.toString() ~ " is not a numeric type");
    }
}

unittest
{
    assert(convertFromJSON!float(JSONValue(3.0)) == 3.0);
    assert(convertFromJSON!int(JSONValue(42)) == 42);
    assert(convertFromJSON!uint(JSONValue(42U)) == 42U);
    assert(convertFromJSON!char(JSONValue('a')) == 'a');

    // quirky JSON cases

    assert(convertFromJSON!int(JSONValue(null)) == 0);
    assert(convertFromJSON!int(JSONValue(false)) == 0);
    assert(convertFromJSON!int(JSONValue(true)) == 1);
    assert(convertFromJSON!int(JSONValue("42")) == 42);
    assert(convertFromJSON!char(JSONValue("a")) == 'a');
}

T convertFromJSON(T)(JSONValue json) if (isBoolean!T)
{
    import std.json : JSON_TYPE;

    switch (json.type)
    {
    case JSON_TYPE.NULL, JSON_TYPE.FALSE:
        return false;

    case JSON_TYPE.FLOAT:
        return json.floating != 0;

    case JSON_TYPE.INTEGER:
        return json.integer != 0;

    case JSON_TYPE.UINTEGER:
        return json.uinteger != 0;

    case JSON_TYPE.STRING:
        return json.str.length > 0;

    default:
        return true;
    }
}

unittest
{
    assert(convertFromJSON!bool(JSONValue(false)) == false);
    assert(convertFromJSON!bool(JSONValue(true)) == true);

    // quirky JSON cases

    assert(convertFromJSON!bool(JSONValue(null)) == false);
    assert(convertFromJSON!bool(JSONValue(0.0)) == false);
    assert(convertFromJSON!bool(JSONValue(0)) == false);
    assert(convertFromJSON!bool(JSONValue(0U)) == false);
    assert(convertFromJSON!bool(JSONValue("")) == false);

    assert(convertFromJSON!bool(JSONValue(3.0)) == true);
    assert(convertFromJSON!bool(JSONValue(42)) == true);
    assert(convertFromJSON!bool(JSONValue(42U)) == true);
    assert(convertFromJSON!bool(JSONValue("Hello world")) == true);
    assert(convertFromJSON!bool(JSONValue(new int[0])) == true);
}

T convertFromJSON(T)(JSONValue json)
        if (isSomeString!T || is(T : string) || is(T : wstring) || is(T : dstring))
{
    import std.conv : to;
    import std.json : JSONException, JSON_TYPE;

    static if (is(T == enum))
    {
        foreach (member; __traits(allMembers, T))
        {
            auto m = __traits(getMember, T, member);

            if (json.str == m)
            {
                return m;
            }
        }

        throw new JSONException(json.toString() ~ " is not a member of " ~ typeid(T).toString());
    }
    else
    {
        return (json.type == JSON_TYPE.STRING ? json.str : json.toString()).to!T;
    }
}

unittest
{
    enum Operation : string
    {
        create = "create",
        delete_ = "delete"
    }

    assert(convertFromJSON!Operation(JSONValue("create")) == Operation.create);
    assert(convertFromJSON!Operation(JSONValue("delete")) == Operation.delete_);

    auto json = JSONValue("Hello");
    assert(convertFromJSON!string(json) == json.str);
    assert(convertFromJSON!(char[])(json) == json.str);
    assert(convertFromJSON!(wstring)(json) == "Hello"w);
    assert(convertFromJSON!(wchar[])(json) == "Hello"w);
    assert(convertFromJSON!(dstring)(json) == "Hello"d);
    assert(convertFromJSON!(dchar[])(json) == "Hello"d);

    // beware of the fact that JSONValue treats chars as integers; this returns "97" and not "a"
    assert(convertFromJSON!string(JSONValue('a')) != "a");
    assert(convertFromJSON!string(JSONValue("a")) == "a");

    enum TestEnum : string
    {
        hello = "hello",
        world = "world"
    }

    assert(convertFromJSON!TestEnum(JSONValue("hello")) == TestEnum.hello);
    assert(convertFromJSON!TestEnum(JSONValue("world")) == TestEnum.world);

    // quirky JSON cases

    assert(convertFromJSON!string(JSONValue(null)) == "null");
    assert(convertFromJSON!string(JSONValue(false)) == "false");
    assert(convertFromJSON!string(JSONValue(true)) == "true");
}

T convertFromJSON(T : U[], U)(JSONValue json)
        if (isArray!T && !isSomeString!T && !is(T : string) && !is(T : wstring) && !is(T : dstring))
{
    import std.algorithm : map;
    import std.array : array;
    import std.json : JSONException, JSON_TYPE;

    switch (json.type)
    {
    case JSON_TYPE.NULL:
        return [];

    case JSON_TYPE.FALSE:
        return [convertFromJSON!U(JSONValue(false))];

    case JSON_TYPE.TRUE:
        return [convertFromJSON!U(JSONValue(true))];

    case JSON_TYPE.ARRAY:
        return json.array.map!(value => convertFromJSON!U(value)).array;

    case JSON_TYPE.OBJECT:
        throw new JSONException(json.toString() ~ " is not a string type");

    default:
        return [convertFromJSON!U(json)];
    }
}

unittest
{
    assert(convertFromJSON!(int[])(JSONValue([0, 1, 2, 3])) == [0, 1, 2, 3]);

    // quirky JSON cases

    assert(convertFromJSON!(int[])(JSONValue(null)) == []);
    assert(convertFromJSON!(int[])(JSONValue(false)) == [0]);
    assert(convertFromJSON!(bool[])(JSONValue(true)) == [true]);
    assert(convertFromJSON!(float[])(JSONValue(3.0)) == [3.0]);
    assert(convertFromJSON!(int[])(JSONValue(42)) == [42]);
    assert(convertFromJSON!(uint[])(JSONValue(42U)) == [42U]);
    assert(convertFromJSON!(string[])(JSONValue("Hello")) == ["Hello"]);
}

T convertFromJSON(T : U[string], U)(JSONValue json) if (isAssociativeArray!T)
{
    import std.conv : text;
    import std.json : JSONException, JSON_TYPE;

    U[string] result;

    switch (json.type)
    {
    case JSON_TYPE.NULL:
        return result;

    case JSON_TYPE.OBJECT:
        foreach (key, value; json.object)
        {
            result[key] = convertFromJSON!U(value);
        }

        break;

    case JSON_TYPE.ARRAY:
        foreach (key, value; json.array)
        {
            result[text(key)] = convertFromJSON!U(value);
        }

        break;

    default:
        throw new JSONException(json.toString() ~ " is not an object type");
    }

    return result;
}

unittest
{
    auto dictionary = ["hello" : 42, "world" : 0];
    assert(convertFromJSON!(int[string])(JSONValue(dictionary)) == dictionary);

    // quirky JSON cases

    assert(convertFromJSON!(int[string])(JSONValue([16, 42])) == ["0" : 16, "1" : 42]);
    dictionary.clear();
    assert(convertFromJSON!(int[string])(JSONValue(null)) == dictionary);
}

Nullable!JSONValue convertToJSON(T)(T value)
        if ((is(T == class) || is(T == struct) || is(T == interface)) && !is(T == JSONValue))
{
    import std.meta : Alias;
    import std.traits : isSomeFunction, isType;
    import std.typecons : nullable;

    static if (is(T == class))
    {
        if (value is null)
        {
            return JSONValue(null).nullable;
        }
    }

    auto result = JSONValue();

    foreach (member; __traits(allMembers, T))
    {
        alias m = Alias!(__traits(getMember, T, member));

        static if (__traits(getProtection, m) == "public" && !isType!(m) && !isSomeFunction!(m))
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

unittest
{
    import std.json : parseJSON;

    auto testClass = new TestClass();
    testClass.integer = 42;
    testClass.floating = 3.5;
    testClass.text = "Hello world";
    testClass.array = [0, 1, 2];
    testClass.dictionary = ["key1" : "value1", "key2" : "value2"];
    testClass.testStruct = TestStruct();
    testClass.testStruct.uinteger = 16;
    testClass.testStruct.json = JSONValue(["key1" : "value1", "key2" : "value2"]);

    auto jsonString = `{
        "integer": 42,
        "floating": 3.5,
        "text": "Hello world",
        "array": [0, 1, 2],
        "dictionary": {
            "key1": "value1",
            "key2": "value2"
        },
        "testStruct": {
            "uinteger": 16,
            "json": {
                "key1": "value1",
                "key2": "value2"
            }
        }
    }`;

    auto json = convertToJSON(testClass);
    // parseJSON() will parse `uinteger` as a regular integer, meaning that the JSON's aren't considered equal,
    // even though technically they are equivalent (16 as int or as uint is technically the same value), which
    // is why .toString() is used here
    assert(json.get().toString() == parseJSON(jsonString).toString());

    TestClass nullTestClass = null;
    auto nullJson = convertToJSON(nullTestClass);
    assert(!nullJson.isNull && nullJson.get().isNull);
}

Nullable!JSONValue convertToJSON(N : Nullable!T, T)(N value)
{
    return value.isNull ? Nullable!JSONValue() : convertToJSON!T(value.get());
}

unittest
{
    assert(convertToJSON(Nullable!int()) == Nullable!JSONValue());
    assert(convertToJSON(Nullable!int(42)) == JSONValue(42));
}

Nullable!JSONValue convertToJSON(T)(T value)
        if ((!is(T == class) && !is(T == struct) && !is(T == interface)) || is(T == JSONValue))
{
    import std.typecons : nullable;

    return JSONValue(value).nullable;
}

unittest
{
    assert(convertToJSON(3.0) == JSONValue(3.0));
    assert(convertToJSON(42) == JSONValue(42));
    assert(convertToJSON(42U) == JSONValue(42U));
    assert(convertToJSON(false) == JSONValue(false));
    assert(convertToJSON(true) == JSONValue(true));
    assert(convertToJSON('a') == JSONValue('a'));
    assert(convertToJSON("Hello world") == JSONValue("Hello world"));
    assert(convertToJSON(JSONValue(42)) == JSONValue(42));
}

Nullable!JSONValue convertToJSON(T : U[], U)(T value)
        if (isArray!T && !isSomeString!T && !is(T : string) && !is(T : wstring) && !is(T : dstring))
{
    import std.algorithm : map;
    import std.array : array;
    import std.typecons : nullable;

    return JSONValue(value.map!(item => convertToJSON(item))()
            .map!(json => json.isNull ? JSONValue(null) : json).array).nullable;
}

unittest
{
    assert(convertToJSON([0, 1, 2]) == JSONValue([0, 1, 2]));
    assert(convertToJSON(["hello", "world"]) == JSONValue(["hello", "world"]));
}

Nullable!JSONValue convertToJSON(T : U[K], U, K)(T value) if (isAssociativeArray!T)
{
    import std.conv : text;
    import std.typecons : nullable;

    auto result = JSONValue();

    foreach (key; value.keys)
    {
        auto json = convertToJSON(value[key]);
        result[text(key)] = json.isNull ? JSONValue(null) : json;
    }

    return result.nullable;
}

unittest
{
    assert(convertToJSON(["hello" : 16, "world" : 42]) == JSONValue(["hello" : 16, "world" : 42]));
    assert(convertToJSON(['a' : 16, 'b' : 42]) == JSONValue(["a" : 16, "b" : 42]));
    assert(convertToJSON([0 : 16, 1 : 42]) == JSONValue(["0" : 16, "1" : 42]));
}

/++
Removes underscores from names. Some protocol variable names can be reserved
names (like `version`) and thus have an added underscore in their protocol
definition.
+/
private string normalizeMemberName(const string name)
{
    import std.string : endsWith;

    return name.endsWith('_') ? name[0 .. $ - 1] : name;
}

unittest
{
    assert(normalizeMemberName("hello") == "hello");
    assert(normalizeMemberName("hello_") == "hello");
    assert(normalizeMemberName("_hello") == "_hello");
    assert(normalizeMemberName("hel_lo") == "hel_lo");
}
