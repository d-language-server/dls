module dls.util.document;

import dls.util.uri : Uri;

class Document
{
    import dls.protocol.definitions : Position, Range, TextDocumentIdentifier,
        TextDocumentItem, VersionedTextDocumentIdentifier;
    import dls.protocol.interfaces : TextDocumentContentChangeEvent;
    import std.utf : codeLength, toUTF8;

    private static Document[string] _documents;
    private wstring[] _lines;

    static Document opIndex(in Uri uri)
    {
        return uri.path in _documents ? _documents[uri.path] : null;
    }

    @property static auto uris()
    {
        import std.algorithm : map;

        return _documents.keys.map!(path => Uri.fromPath(path));
    }

    static void open(in TextDocumentItem textDocument)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents.remove(path);
        }

        _documents[path] = new Document(textDocument);
    }

    static void close(in TextDocumentIdentifier textDocument)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents.remove(path);
        }
    }

    static void change(in VersionedTextDocumentIdentifier textDocument,
            TextDocumentContentChangeEvent[] events)
    {
        auto path = Uri.getPath(textDocument.uri);

        if (path in _documents)
        {
            _documents[path].change(events);
        }
    }

    @property const(wstring[]) lines() const
    {
        return _lines;
    }

    this(in TextDocumentItem textDocument)
    {
        _lines = getText(textDocument.text);
    }

    override string toString() const
    {
        import std.range : join;

        return _lines.join().toUTF8();
    }

    size_t byteAtPosition(in Position position)
    {
        import std.algorithm : reduce;
        import std.range : iota;

        const linesBytes = reduce!((s, i) => s + codeLength!char(_lines[i]))(cast(size_t) 0,
                iota(position.line));
        const characterBytes = codeLength!char(_lines[position.line][0 .. position.character]);
        return linesBytes + characterBytes;
    }

    Range wordRangeAtByte(size_t bytePosition)
    {
        import std.algorithm : min;

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
        return wordRangeAtLineAndByte(lineNumber, min(bytePosition - bytes, line.length));
    }

    Range wordRangeAtLineAndByte(size_t lineNumber, size_t bytePosition)
    {
        import std.regex : matchAll, regex;
        import std.utf : UTFException, validate;

        const line = _lines[lineNumber];
        size_t startCharacter;
        const lineSlice = line.toUTF8()[0 .. bytePosition];

        try
        {
            validate(lineSlice);
            startCharacter = codeLength!wchar(lineSlice);
        }
        catch (UTFException e)
        {
            // TODO: properly use document buffers instead of on-disc files
        }

        auto word = matchAll(line[startCharacter .. $], regex(`\w+|.`w));
        return new Range(new Position(lineNumber, startCharacter),
                new Position(lineNumber, startCharacter + (word ? word.hit.length : 0)));
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
        import std.array : array, replaceFirst;
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
