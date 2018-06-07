shared static this()
{
    import dls.util.setup : initialSetup;

    initialSetup();
}

int main()
{
    import dls.server : Server;

    Server.loop();
    return 0;
}
