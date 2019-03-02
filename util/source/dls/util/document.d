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
    import dls.protocol.definitions : DocumentUri, Position, Range,
        TextDocumentIdentifier, TextDocumentItem, VersionedTextDocumentIdentifier;
    import dls.protocol.interfaces : TextDocumentContentChangeEvent;
    import std.json : JSONValue;

    private static Document[string] _documents;
    private DocumentUri _uri;
    private wstring[] _lines;
    private JSONValue _version;

    @property static auto uris()
    {
        import std.algorithm : map;

        return _documents.byValue.map!(doc => new Uri(doc._uri));
    }

    static Document get(const Uri uri)
    {
        import std.file : readText;

        return uri.path in _documents ? _documents[uri.path] : new Document(uri, readText(uri.path));
    }

    static bool open(const TextDocumentItem textDocument)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path !in _documents)
        {
            _documents[uri.path] = new Document(uri, textDocument.text);
            _documents[uri.path]._version = textDocument.version_;
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool close(const TextDocumentIdentifier textDocument)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path in _documents)
        {
            _documents.remove(uri.path);
            return true;
        }
        else
        {
            return false;
        }
    }

    static bool change(const VersionedTextDocumentIdentifier textDocument,
            TextDocumentContentChangeEvent[] events)
    {
        auto uri = new Uri(textDocument.uri);

        if (uri.path in _documents)
        {
            _documents[uri.path].change(events);
            _documents[uri.path]._version = textDocument.version_;
            return true;
        }
        else
        {
            return false;
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

    private this(const Uri uri, const string text)
    {
        _uri = uri;
        _lines = getText(text);
    }

    override string toString() const
    {
        import std.range : join;
        import std.utf : toUTF8;

        return _lines.join().toUTF8();
    }

    void validatePosition(const Position position) const
    {
        import dls.protocol.errors : InvalidParamsException;
        import std.format : format;

        if (position.line >= _lines.length || position.character > _lines[position.line].length)
        {
            throw new InvalidParamsException(format!"invalid position: %s %s,%s"(_uri,
                    position.line, position.character));
        }
    }

    size_t byteAtPosition(const Position position) const
    {
        import std.algorithm : reduce;
        import std.range : iota;
        import std.utf : codeLength;

        if (position.line >= _lines.length)
        {
            return 0;
        }

        immutable linesBytes = reduce!((s, i) => s + codeLength!char(_lines[i]))(
                cast(size_t) 0, iota(position.line));

        if (position.character > _lines[position.line].length)
        {
            return 0;
        }

        immutable characterBytes = codeLength!char(_lines[position.line][0 .. position.character]);
        return linesBytes + characterBytes;
    }

    Position positionAtByte(size_t bytePosition) const
    {
        import std.algorithm : min;
        import std.utf : codeLength, toUTF8;

        size_t i;
        size_t bytes;

        while (bytes <= bytePosition && i < _lines.length)
        {
            bytes += codeLength!char(_lines[i]);
            ++i;
        }

        immutable lineNumber = minusOne(i);
        immutable line = _lines[lineNumber];
        bytes -= codeLength!char(line);
        immutable columnByte = min(bytePosition - bytes, line.length);
        immutable columnNumber = codeLength!wchar(line.toUTF8()[0 .. columnByte]);
        return new Position(lineNumber, columnNumber);
    }

    Range wordRangeAtPosition(const Position position) const
    {
        import std.algorithm : min;

        immutable line = _lines[min(position.line, $ - 1)];
        immutable middleIndex = min(position.character, line.length);
        size_t startIndex = middleIndex;
        size_t endIndex = middleIndex;

        static bool isIdentifierChar(wchar c)
        {
            import std.ascii : isPunctuation, isWhite;

            return !isWhite(c) && (!isPunctuation(c) || c == '_');
        }

        while (startIndex > 0 && isIdentifierChar(line[minusOne(startIndex)]))
        {
            --startIndex;
        }

        while (endIndex < line.length && isIdentifierChar(line[endIndex]))
        {
            ++endIndex;
        }

        return new Range(new Position(position.line, startIndex),
                new Position(position.line, endIndex));
    }

    Range wordRangeAtLineAndByte(size_t lineNumber, size_t bytePosition) const
    {
        import std.algorithm : min;
        import std.utf : codeLength, toUTF8;

        return wordRangeAtPosition(new Position(lineNumber,
                codeLength!wchar(_lines[lineNumber].toUTF8()[0 .. min(bytePosition, $)])));
    }

    Range wordRangeAtByte(size_t bytePosition) const
    {
        return wordRangeAtPosition(positionAtByte(bytePosition));
    }

    private void change(const TextDocumentContentChangeEvent[] events)
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

    private wstring[] getText(const string text) const
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

size_t minusOne(size_t i)
{
    return i > 0 ? i - 1 : 0;
}
