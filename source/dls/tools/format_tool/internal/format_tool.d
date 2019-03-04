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

module dls.tools.format_tool.internal.format_tool;

import dls.protocol.definitions : Range;
import dls.tools.tool : Tool;

abstract class FormatTool : Tool
{
    import dls.protocol.definitions : Position, TextEdit;
    import dls.protocol.interfaces : FormattingOptions;
    import dls.util.uri : Uri;

    private static FormatTool _instance;

    static void initialize(FormatTool tool)
    {
        import dls.tools.configuration : Configuration;
        import dls.tools.format_tool.internal.dfmt_format_tool : DfmtFormatTool;
        import dls.tools.format_tool.internal.indent_format_tool : IndentFormatTool;

        _instance = tool;
        _instance.addConfigHook("engine", (const Uri uri) {
            auto config = getConfig(null);

            if (config.format.engine == Configuration.FormatConfiguration.Engine.dfmt
                && typeid(_instance) == typeid(DfmtFormatTool))
            {
                return;
            }

            FormatTool.shutdown();
            FormatTool.initialize(config.format.engine == Configuration.FormatConfiguration.Engine.dfmt
                ? new DfmtFormatTool() : new IndentFormatTool());
        });
    }

    static void shutdown()
    {
        _instance.removeConfigHooks();
        destroy(_instance);
    }

    @property static FormatTool instance()
    {
        return _instance;
    }

    TextEdit[] formatting(const Uri uri, const FormattingOptions options);

    TextEdit[] rangeFormatting(const Uri uri, const Range range, const FormattingOptions options)
    {
        import dls.util.document : Document;
        import std.algorithm : filter;
        import std.array : array;

        const document = Document.get(uri);
        document.validatePosition(range.start);
        return formatting(uri, options).filter!((edit) => edit.range.isValidEditFor(range)).array;
    }

    TextEdit[] onTypeFormatting(const Uri uri, const Position position,
            const FormattingOptions options)
    {
        import dls.util.document : Document;
        import std.algorithm : filter;
        import std.array : array;
        import std.string : stripRight;

        const document = Document.get(uri);
        document.validatePosition(position);

        if (position.character != stripRight(document.lines[position.line]).length)
        {
            return [];
        }

        return formatting(uri, options).filter!(edit => edit.range.start.line == position.line
                || edit.range.end.line == position.line).array;
    }
}

package bool isValidEditFor(const Range editRange, const Range formatRange)
{
    //dfmt off
    return (editRange.start.line < formatRange.end.line
        || (editRange.start.line == formatRange.end.line && editRange.start.character < formatRange.end.character))
        && (editRange.end.line > formatRange.start.line
        || (editRange.end.line == formatRange.start.line && editRange.end.character > formatRange.start.character));
    //dfmt on
}
