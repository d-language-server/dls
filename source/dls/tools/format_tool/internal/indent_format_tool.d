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

module dls.tools.format_tool.internal.indent_format_tool;

import dls.tools.format_tool.internal.format_tool : FormatTool;

class IndentFormatTool : FormatTool
{
    import dls.protocol.definitions : Position, Range, TextEdit;
    import dls.protocol.interfaces : FormattingOptions;
    import dls.util.uri : Uri;

    override TextEdit[] formatting(const Uri uri, const FormattingOptions options)
    {
        return [];
    }

    override TextEdit[] rangeFormatting(const Uri uri, const Range range,
            const FormattingOptions options)
    {
        return [];
    }

    override TextEdit[] onTypeFormatting(const Uri uri, const Position position,
            const FormattingOptions options)
    {
        return [];
    }
}
