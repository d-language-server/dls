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

module dls.util.document;

class Document
{
    import dls.util.uri : Uri;
    import dls.protocol.definitions : Position, Range, TextDocumentIdentifier,
        TextDocumentItem, VersionedTextDocumentIdentifier;
    import dls.protocol.interfaces : TextDocumentContentChangeEvent;
    import std.json : JSONValue;

    private static Document[string] _documents;
    private wstring[] _lines;
    private JSONValue _version;

    @property static auto uris()
    {
        import std.algorithm : map;

        return _documents.keys.map!(path => Uri.fromPath(path));
    }

    static Document get(in Uri uri)
    {
        import std.file : readText;

        return uri.path in _documents ? _documents[uri.path] : new Document(readText(uri.path));
    }

    static void open(in TextDocumentItem textDocument)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path !in _documents)
        {
            _documents[uri.path] = new Document(textDocument.text);
            _documents[uri.path]._version = textDocument.version_;
        }
    }

    static void close(in TextDocumentIdentifier textDocument)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path in _documents)
        {
            _documents.remove(uri.path);
        }
    }

    static void change(in VersionedTextDocumentIdentifier textDocument,
            TextDocumentContentChangeEvent[] events)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path in _documents)
        {
            _documents[uri.path].change(events);
            _documents[uri.path]._version = textDocument.version_;
        }
    }

    @property const(wstring[]) lines() const
    {
        return _lines;
    }

    @property JSONValue version_() const
    {
        return _version;
    }

    private this(in string text)
    {
        _lines = getText(text);
    }

    override string toString() const
    {
        import std.range : join;
        import std.utf : toUTF8;

        return _lines.join().toUTF8();
    }

    bool validatePosition(in Position position)
    {
        return position.line < _lines.length && position.character < _lines[position.line].length;
    }

    size_t byteAtPosition(in Position position)
    {
        import std.algorithm : reduce;
        import std.range : iota;
        import std.utf : codeLength;

        if (position.line >= _lines.length)
        {
            return 0;
        }

        const linesBytes = reduce!((s, i) => s + codeLength!char(_lines[i]))(cast(size_t) 0,
                iota(position.line));

        if (position.character >= _lines[position.line].length)
        {
            return 0;
        }

        const characterBytes = codeLength!char(_lines[position.line][0 .. position.character]);
        return linesBytes + characterBytes;
    }

    Position positionAtByte(size_t bytePosition)
    {
        import std.algorithm : min;
        import std.utf : codeLength, toUCSindex;

        size_t i;
        size_t bytes;

        while (bytes <= bytePosition && i < _lines.length)
        {
            bytes += codeLength!char(_lines[i]);
            ++i;
        }

        const lineNumber = i - 1;
        const line = _lines[lineNumber];
        bytes -= codeLength!char(line);
        const columnNumber = toUCSindex(line, min(bytePosition - bytes, line.length));
        return new Position(lineNumber, columnNumber);
    }

    Range wordRangeAtByte(size_t bytePosition)
    {
        return wordRangeAtPosition(positionAtByte(bytePosition));
    }

    Range wordRangeAtPosition(in Position position)
    {
        import std.algorithm : min;
        import std.regex : matchAll, regex;

        const line = _lines[min(position.line, $ - 1)];
        const startCharacter = min(position.character, line.length);
        auto word = matchAll(line[startCharacter .. $], regex(`\w+|.`w));
        return new Range(new Position(position.line, startCharacter),
                new Position(position.line, startCharacter + (word ? word.hit.length : 0)));
    }

    Range wordRangeAtLineAndByte(size_t lineNumber, size_t bytePosition)
    {
        import std.utf : toUCSindex;

        return wordRangeAtPosition(new Position(lineNumber,
                toUCSindex(_lines[lineNumber], bytePosition)));
    }

    private void change(in TextDocumentContentChangeEvent[] events)
    {
        foreach (event; events)
        {
            if (event.range.isNull)
            {
                _lines = getText(event.text);
            }
            else
            {
                with (event.range)
                {
                    auto linesBefore = _lines[0 .. start.line];
                    auto linesAfter = _lines[end.line + 1 .. $];

                    auto lineStart = _lines[start.line][0 .. start.character];
                    auto lineEnd = _lines[end.line][end.character .. $];

                    auto newLines = getText(event.text);

                    if (newLines.length)
                    {
                        newLines[0] = lineStart ~ newLines[0];
                        newLines[$ - 1] = newLines[$ - 1] ~ lineEnd;
                    }
                    else
                    {
                        newLines = [lineStart ~ lineEnd];
                    }

                    _lines = linesBefore ~ newLines ~ linesAfter;
                }
            }
        }
    }

    private wstring[] getText(in string text) const
    {
        import std.algorithm : endsWith;
        import std.array : replaceFirst;
        import std.encoding : getBOM;
        import std.string : splitLines;
        import std.typecons : Yes;
        import std.utf : toUTF16;

        auto lines = text.replaceFirst(cast(string) getBOM(cast(ubyte[]) text)
                .sequence, "").toUTF16().splitLines(Yes.keepTerminator);

        if (!lines.length || lines[$ - 1].endsWith('\r', '\n'))
        {
            lines ~= "";
        }

        return lines;
    }
}
