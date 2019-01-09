import std.stdio;

void main()
{
    auto var = 42;
    writeln("Edit source/app.d to start your project.");
}

class Class
{
    int number;

    union
    {
        int anonymous;
        string symbol;
    }
}

struct Struct
{
    string name;
}

enum Enum
{
    foo,
    bar,
    baz
}
