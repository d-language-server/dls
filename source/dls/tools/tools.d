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

module dls.tools.tools;

final class Tools
{
    import dls.tools.analysis_tool : AnalysisTool;
    import dls.tools.configuration : Configuration;
    import dls.tools.format_tool : FormatTool;
    import dls.tools.symbol_tool : SymbolTool;

    static SymbolTool symbolTool;
    static AnalysisTool analysisTool;
    static FormatTool formatTool;

    static void initialize()
    {
        symbolTool = new SymbolTool();
        analysisTool = new AnalysisTool();
        formatTool = new FormatTool();
    }

    static void setConfiguration(Configuration c)
    {
        import dls.tools.tool : Tool;

        Tool._configuration = c;
        symbolTool.importDirectories!true("", c.symbol.importPaths);
    }
}
