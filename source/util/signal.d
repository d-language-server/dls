module util.signal;

private struct S(uint i)
{
}

interface Signal
{
    static alias MessageAtFront = S!0;
}
