module dls.util.uri;

import dls.protocol.definitions;
import std.regex;

class Uri
{
    private static enum _reg = regex(
                `([\w-]+)://([\w.]+(?::\d+)?)?([^\?#]+)(?:\?([\w=&]+))?(?:#([\w-]+))?`);
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
        auto matches = matchAll(uri, _reg);

        //dfmt off
        _uri        = uri;
        _scheme     = matches.front[1];
        _authority  = matches.front[2];
        _path       = matches.front[3];
        _query      = matches.front[4];
        _fragment   = matches.front[5];
        //dfmt on
    }

    override string toString() const
    {
        return _uri;
    }

    alias toString this;
}
