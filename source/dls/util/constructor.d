module dls.util.constructor;

mixin template Constructor(T)
{
    this()
    {
        foreach (member; __traits(derivedMembers, T))
        {
            static if (is(typeof(__traits(getMember, T, member)) == class))
            {
                mixin(member ~ " = new " ~ __traits(identifier,
                        typeof(__traits(getMember, T, member))) ~ "();");
            }
        }
    }
}
