module dls.util.document;

import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.util.uri : Uri;

class Document
{
    import std.utf : codeLength, toUTF8;

    private static Document[string] _documents;
    private wstring[] _lines;

    static auto opIndex(Uri uri)
    {
        return uri.path in _documents ? _documents[uri.path] : null;
    }

    static auto opIndex(string uri)
    {
        auto path = Uri.getPath(uri);
        return path in _documents ? _documents[path] : null;
    }

    @property static auto uris()
    {
        import std.algorithm : map;

        return _documents.keys.map!(path => Uri.fromPath(path));
    }

    static void open(TextDocumentItem textDocument)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents.remove(path);
        }

        _documents[path] = new Document(textDocument);
    }

    static void close(TextDocumentIdentifier textDocument)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents.remove(path);
        }
    }

    static void change(VersionedTextDocumentIdentifier textDocument,
            TextDocumentContentChangeEvent[] events)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents[path].change(events);
        }
    }

    @property auto lines() const
    {
        return _lines;
    }

    this(TextDocumentItem textDocument)
    {
        _lines = getText(textDocument.text);
    }

    override string toString() const
    {
        import std.range : join;

        return _lines.join().toUTF8();
    }

    auto byteAtPosition(Position position)
    {
        import std.algorithm : reduce;
        import std.range : iota;

        const linesBytes = reduce!((s, i) => s + codeLength!char(_lines[i]))(cast(size_t) 0,
                iota(position.line));
        const characterBytes = codeLength!char(_lines[position.line][0 .. position.character]);
        return linesBytes + characterBytes;
    }

    auto wordRangeAtByte(size_t bytePosition)
    {
        size_t i;
        size_t bytes;

        while (bytes <= bytePosition && i < _lines.length)
        {
            bytes += codeLength!char(_lines[i]);
            ++i;
        }

        const lineNumber = i - 1;
        bytes -= codeLength!char(_lines[lineNumber]);
        return wordRangeAtLineAndByte(lineNumber, bytePosition - bytes);
    }

    auto wordRangeAtLineAndByte(size_t lineNumber, size_t bytePosition)
    {
        import std.regex : ctRegex, matchAll;
        import std.utf : toUCSindex;

        const line = _lines[lineNumber];
        const startCharacter = toUCSindex(line.toUTF8(), bytePosition);
        auto word = matchAll(line[startCharacter .. $], ctRegex!`\w+|.`w);
        auto range = new Range();
        range.start.line = lineNumber;
        range.start.character = startCharacter;
        range.end.line = lineNumber;
        range.end.character = startCharacter + word.hit.length;
        return range;
    }

    private void change(TextDocumentContentChangeEvent[] events)
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

    private auto getText(string text) const
    {
        import std.algorithm : endsWith;
        import std.array : array;
        import std.string : lineSplitter;
        import std.typecons : Yes;
        import std.utf : toUTF16;

        auto lines = lineSplitter!(Yes.keepTerminator)(text.toUTF16()).array;

        if (!lines.length || lines[$ - 1].endsWith('\r', '\n'))
        {
            lines ~= "";
        }

        return lines;
    }
}
