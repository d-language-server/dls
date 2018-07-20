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
    SymbolConfiguration symbol;
    AnalysisConfiguration analysis;
    FormatConfiguration format;

    this()
    {
        symbol = new SymbolConfiguration();
        analysis = new AnalysisConfiguration();
        format = new FormatConfiguration();
    }

    static class SymbolConfiguration
    {
        string[] importPaths;
    }

    static class AnalysisConfiguration
    {
        string configFile = "dscanner.ini";
    }

    static class FormatConfiguration
    {
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

        static enum TemplateConstraintStyle : string
        {
            conditionalNewlineIndent = "conditionalNewlineIndent",
            conditionalNewline = "conditionalNewline",
            alwaysNewline = "alwaysNewline",
            alwaysNewlineIndent = "alwaysNewlineIndent"
        }

        EndOfLine endOfLine = EndOfLine.lf;
        int maxLineLength = 120;
        bool dfmtAlignSwitchStatements = true;
        BraceStyle dfmtBraceStyle = BraceStyle.allman;
        bool dfmtOutdentAttributes = true;
        int dfmtSoftMaxLineLength = 80;
        bool dfmtSpaceAfterCast = true;
        bool dfmtSpaceAfterKeywords = true;
        bool dfmtSpaceBeforeFunctionParameters = false;
        bool dfmtSplitOperatorAtLineEnd = false;
        bool dfmtSelectiveImportSpace = true;
        bool dfmtCompactLabeledStatements = true;
        TemplateConstraintStyle dfmtTemplateConstraintStyle = TemplateConstraintStyle
            .conditionalNewlineIndent;
        bool dfmtSingleTemplateConstraintIndent = false;
    }
}
