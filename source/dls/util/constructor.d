module dls.util.constructor;

mixin template Constructor(T)
{
    @safe this()
    {
        foreach (member; __traits(derivedMembers, T))
        {
            static if (is(typeof(__traits(getMember, T, member)) == class))
            {
                import std.format : format;

                mixin(format!"%s = new %s();"(member, __traits(identifier,
                        typeof(__traits(getMember, T, member)))));
            }
        }
    }
}
