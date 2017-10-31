module dls.tools.formatter;

import dfmt.config;
import dfmt.editorconfig;
import dfmt.formatter;
import dls.protocol.configuration;
import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.util.document;
import std.algorithm;
import std.outbuffer;
import std.range;

private immutable EOL[FormatterConfiguration.EndOfLine] eolMap;

shared static this()
{
    eolMap = [FormatterConfiguration.EndOfLine.lf : EOL.lf, FormatterConfiguration.EndOfLine.cr
        : EOL.cr, FormatterConfiguration.EndOfLine.crlf : EOL.crlf];
}

class Formatter
{
    static private auto configuration = new shared FormatterConfiguration();

    static auto formatFile(DocumentUri uri, FormattingOptions options)
    {
        const document = Document[uri];
        auto contents = cast(ubyte[]) document.toString();
        auto config = Config();
        auto buffer = new OutBuffer();
        auto range = new Range();

        range.end.line = document.lines.length;
        range.end.character = document.lines[$ - 1].length;

        config.indent_size = cast(typeof(config.indent_size)) options.tabSize;
        config.indent_style = options.insertSpaces ? IndentStyle.space : IndentStyle.tab;
        config.end_of_line = eolMap[configuration.endOfLine];

        format(uri, contents, buffer, &config);

        return tuple(buffer.toString(), range);
    }
}
