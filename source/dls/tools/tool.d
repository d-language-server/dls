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

private alias Hook = void delegate();

abstract class Tool
{
    import dls.tools.configuration : Configuration;
    import std.json : JSONValue;

    protected static Configuration _configuration;
    private static Hook[string] _configHooks;

    static this()
    {
        _configuration = new Configuration();
    }

    static void mergeConfig(JSONValue json)
    {
        _configuration.merge(json);

        foreach (hook; _configHooks)
        {
            hook();
        }
    }

    protected static void addConfigHook(string name, Hook hook)
    {
        _configHooks[name] = hook;
    }

    protected static void removeConfigHook(string name)
    {
        _configHooks.remove(name);
    }

    static void initialize();
    static void shutdown();
    @property static T instance(T : Tool)();
}
