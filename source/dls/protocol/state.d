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

@property InitializeParams initState()
{
    return _initState is null ? new InitializeParams() : _initState;
}

@property void initState(InitializeParams params)
{
    import dls.util.logger : logger;

    _initState = params;

    debug
    {
        logger.trace = InitializeParams.Trace.verbose;
    }
    else
    {
        logger.trace = params.trace;
    }
}

@property InitializeParams.InitializationOptions initOptions()
{
    return initState.initializationOptions.isNull
        ? new InitializeParams.InitializationOptions() : _initState.initializationOptions;
}
