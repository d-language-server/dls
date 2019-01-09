import std.stdio;

class Foo
{
    int member;
}

void main()
{
    auto foo = new Foo();
    writeln(foo.member);
    foo.member += 42;
    writeln(foo.member);
}
