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

    protected static Configuration _configuration;
    private static Hook[] _configHooks;

    @property static void configuration(Configuration config)
    {
        _configuration = config;

        foreach (hook; _configHooks)
        {
            hook();
        }
    }

    static this()
    {
        configuration = new Configuration();
    }

    protected static void addConfigHook(Hook hook)
    {
        _configHooks ~= hook;
    }

    static void initialize();
    static void shutdown();
    @property static T instance(T : Tool)();
}
