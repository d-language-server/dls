module dls.util.uri;

class Uri
{
    import dls.protocol.definitions : DocumentUri;
    import std.regex : ctRegex, matchAll;

    private static enum _reg = ctRegex!`(?:([\w-]+)://)?([\w.]+(?::\d+)?)?([^\?#]+)(?:\?([\w=&]+))?(?:#([\w-]+))?`;
    private string _uri;
    private string _scheme;
    private string _authority;
    private string _path;
    private string _query;
    private string _fragment;

    @property auto opDispatch(string name)() const
    {
        mixin("return _" ~ name ~ ";");
    }

    this(DocumentUri uri)
    {
        import std.conv : to;
        import std.path : asNormalizedPath;
        import std.uri : decodeComponent;
        import std.utf : toUTF32;

        auto matches = matchAll(decodeComponent(uri.toUTF32()), _reg);

        //dfmt off
        _uri        = uri;
        _scheme     = matches.front[1];
        _authority  = matches.front[2];
        _path       = matches.front[3].asNormalizedPath().to!string;
        _query      = matches.front[4];
        _fragment   = matches.front[5];
        //dfmt on

        version (Windows)
        {
            if (_path.length && _path[0] == '/')
            {
                _path = _path[1 .. $];
            }
        }
    }

    override string toString() const
    {
        return _uri;
    }

    static auto getPath(DocumentUri uri)
    {
        return new Uri(uri).path;
    }

    static fromPath(string path)
    {
        import std.algorithm : startsWith;

        return new Uri("file://" ~ (path.startsWith('/') ? "" : "/") ~ path);
    }

    alias toString this;
}
