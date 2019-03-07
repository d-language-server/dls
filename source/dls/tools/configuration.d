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

module dls.tools.configuration;

class Configuration
{
    import std.json : JSONValue;

    static class SymbolConfiguration
    {
        string[] importPaths;
        bool listLocalSymbols;
    }

    static class AnalysisConfiguration
    {
        string configFile = "dscanner.ini";
        string[] filePatterns = [];
    }

    static class FormatConfiguration
    {
        static enum Engine : string
        {
            dfmt = "dfmt",
            builtin = "builtin"
        }

        static enum BraceStyle : string
        {
            allman = "allman",
            otbs = "otbs",
            stroustrup = "stroustrup"
        }

        static enum EndOfLine : string
        {
            lf = "lf",
            cr = "cr",
            crlf = "crlf"
        }

        static enum TemplateConstraintsStyle : string
        {
            conditionalNewlineIndent = "conditionalNewlineIndent",
            conditionalNewline = "conditionalNewline",
            alwaysNewline = "alwaysNewline",
            alwaysNewlineIndent = "alwaysNewlineIndent"
        }

        Engine engine = Engine.dfmt;
        EndOfLine endOfLine = EndOfLine.lf;
        bool insertFinalNewline = true;
        bool trimTrailingWhitespace = true;
        int maxLineLength = 120;
        int softMaxLineLength = 80;
        BraceStyle braceStyle = BraceStyle.allman;
        bool spaceAfterCasts = true;
        bool spaceAfterKeywords = true;
        bool spaceBeforeAAColons = false;
        bool spaceBeforeFunctionParameters = false;
        bool spaceBeforeSelectiveImportColons = true;
        bool alignSwitchStatements = true;
        bool compactLabeledStatements = true;
        bool outdentAttributes = true;
        bool splitOperatorsAtLineEnd = false;
        TemplateConstraintsStyle templateConstraintsStyle = TemplateConstraintsStyle
            .conditionalNewlineIndent;
        bool templateConstraintsSingleIndent = false;
    }

    SymbolConfiguration symbol;
    AnalysisConfiguration analysis;
    FormatConfiguration format;

    this()
    {
        symbol = new SymbolConfiguration();
        analysis = new AnalysisConfiguration();
        format = new FormatConfiguration();
    }

    void merge(JSONValue json)
    {
        merge!(typeof(this))(json);
    }

    private void merge(T)(JSONValue json)
    {
        import dls.util.json : convertFromJSON;
        import std.json : JSON_TYPE;
        import std.meta : Alias;
        import std.traits : isSomeFunction, isType;

        if (json.type != JSON_TYPE.OBJECT)
        {
            return;
        }

        foreach (member; __traits(allMembers, T))
        {
            if (member !in json)
            {
                continue;
            }

            alias m = Alias!(__traits(getMember, T, member));

            static if (!isType!(m) && !isSomeFunction!(m))
            {
                static if (is(m == class))
                {
                    merge(m, json[member]);
                }
                else
                {
                    m = convertFromJSON!(typeof(m))(json[member]);
                }
            }
        }
    }
}
