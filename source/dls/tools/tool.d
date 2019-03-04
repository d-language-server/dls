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

module dls.tools.tool;

import dls.util.uri : Uri;

alias Hook = void delegate(const Uri uri);

class Tool
{
    import dls.tools.configuration : Configuration;
    import std.json : JSONValue;

    private static Tool _instance;
    private static Configuration _globalConfig;
    private static JSONValue[string] _workspacesConfigs;
    private static Hook[string] _configHooks;

    @property Uri[] workspacesUris()
    {
        import std.algorithm : map, sort;
        import std.array : array;

        return _workspacesConfigs.keys.sort().map!(u => Uri.fromPath(u)).array;
    }

    static void initialize()
    {
        _instance = new Tool();
        _globalConfig = new Configuration();
    }

    static void shutdown()
    {
        _globalConfig = new Configuration();
        _workspacesConfigs.clear();
        _configHooks.clear();
    }

    protected static Configuration getConfig(const Uri uri)
    {
        import dls.util.json : convertToJSON;

        if (uri is null || uri.path !in _workspacesConfigs)
        {
            return _globalConfig;
        }

        auto config = new Configuration();
        config.merge(convertToJSON(_globalConfig));
        config.merge(_workspacesConfigs[uri.path]);
        return config;
    }

    @property static Tool instance()
    {
        return _instance;
    }

    protected this()
    {
    }

    void updateConfig(const Uri uri, JSONValue json)
    {
        import dls.protocol.state : initState;

        if (uri is null || uri.path.length == 0)
        {
            _globalConfig.merge(json);
        }
        else
        {
            _workspacesConfigs[uri.path] = json;
        }

        foreach (hook; _configHooks.byValue)
        {
            hook(uri is null ? initState.rootUri.isNull ? null : new Uri(initState.rootUri) : uri);
        }
    }

    void removeConfig(const Uri uri)
    {
        if (uri in _workspacesConfigs)
        {
            _workspacesConfigs.remove(uri.path);
        }
    }

    protected void addConfigHook(string name, Hook hook)
    {
        _configHooks[this.toString() ~ '/' ~ name] = hook;
    }

    protected void removeConfigHook(string name)
    {
        _configHooks.remove(this.toString() ~ '/' ~ name);
    }
}
