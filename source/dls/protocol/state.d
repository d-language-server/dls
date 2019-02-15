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

module dls.protocol.state;

import dls.protocol.interfaces : InitializeParams;

private InitializeParams _initState;
private InitializeParams.InitializationOptions _commandLineOptions;

static this()
{
    _initState = new InitializeParams();
    _commandLineOptions = new InitializeParams.InitializationOptions();
}

@property InitializeParams initState()
{
    return _initState;
}

@property void initState(InitializeParams params)
{
    import dls.protocol.logger : logger;
    import dls.util.disposable_fiber : DisposableFiber;

    assert(params !is null);
    _initState = params;

    if (!params.trace.isNull)
    {
        logger.trace = params.trace;
    }

    if (_initState.initializationOptions.isNull)
    {
        _initState.initializationOptions = _commandLineOptions;
    }
    else
    {
        merge(params.initializationOptions.get(), _commandLineOptions);
    }

    DisposableFiber.safeMode = initOptions.safeMode;
}

@property InitializeParams.InitializationOptions initOptions()
{
    return initState.initializationOptions.isNull ? _commandLineOptions
        : _initState.initializationOptions;
}

@property void initOptions(InitializeParams.InitializationOptions options)
{
    assert(options !is null);
    _commandLineOptions = options;
}

private void merge(T)(ref T options, const T addins)
{
    import std.meta : Alias;
    import std.traits : isSomeFunction, isType;
    import dls.protocol.logger : logger;

    static if (is(T == class))
    {
        immutable reference = new T();
    }
    else
    {
        immutable reference = T.init;
    }

    foreach (member; __traits(allMembers, T))
    {
        alias m = Alias!(__traits(getMember, T, member));
        alias optionsMember = Alias!(mixin("options." ~ member));
        alias addinsMember = Alias!(mixin("addins." ~ member));

        static if (__traits(getProtection, m) != "public" || isType!m || isSomeFunction!m)
        {
            continue;
        }
        else static if (is(typeof(m) == class))
        {
            merge(mixin("options." ~ member), mixin("addins." ~ member));
        }
        else
        {
            if (mixin("options." ~ member) == mixin("reference." ~ member))
            {
                mixin("options." ~ member) = mixin("addins." ~ member);
            }
        }
    }
}
