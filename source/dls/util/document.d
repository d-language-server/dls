module dls.util.document;

import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.util.uri : Uri;

class Document
{
    import std.utf : codeLength, toUTF8;

    private static Document[string] _documents;
    private wchar[][] _lines;

    static auto opIndex(Uri uri)
    {
        return uri.path in _documents ? _documents[uri.path] : null;
    }

    static auto opIndex(string uri)
    {
        auto path = Uri.getPath(uri);
        return path in _documents ? _documents[path] : null;
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
        return this._lines;
    }

    this(TextDocumentItem textDocument)
    {
        this._lines = this.getText(textDocument.text);
    }

    override string toString() const
    {
        import std.range : join;

        return this._lines.join().toUTF8();
    }

    auto byteAtPosition(Position position)
    {
        import std.algorithm : reduce;
        import std.range : iota;

        const linesBytes = reduce!((s, i) => s + codeLength!char(this._lines[i]))(
                cast(size_t) 0, iota(position.line));
        const characterBytes = codeLength!char(this._lines[position.line][0 .. position.character]);
        return linesBytes + characterBytes;
    }

    auto lineNumberAtByte(size_t bytePosition)
    {
        size_t i;

        for (size_t bytes; bytes <= bytePosition && i < this._lines.length; ++i)
        {
            bytes += codeLength!char(this._lines[i]);
        }

        return i - 1;
    }

    auto wordRangeAtByte(size_t lineNumber, size_t bytePosition)
    {
        import dls.protocol.definitions : Range;
        import std.regex : ctRegex, matchAll;
        import std.utf : toUCSindex, toUTF8;

        const line = this._lines[lineNumber];
        const startCharacter = toUCSindex(line.toUTF8(), bytePosition);
        auto endCharacter = startCharacter + 1;

        while (endCharacter < line.length && ![line[endCharacter]].matchAll(ctRegex!`\w`w).empty())
        {
            ++endCharacter;
        }

        auto range = new Range();
        range.start.line = lineNumber;
        range.start.character = startCharacter;
        range.end.line = lineNumber;
        range.end.character = endCharacter;
        return range;
    }

    private void change(TextDocumentContentChangeEvent[] events)
    {
        foreach (event; events)
        {
            if (event.range.isNull)
            {
                this._lines = this.getText(event.text);
            }
            else
            {
                with (event.range)
                {
                    auto linesBefore = this._lines[0 .. start.line];
                    auto linesAfter = this._lines[end.line + 1 .. $];

                    auto lineStart = this._lines[start.line][0 .. start.character];
                    auto lineEnd = this._lines[end.line][end.character .. $];

                    auto newLines = this.getText(event.text);

                    if (newLines.length)
                    {
                        newLines[0] = lineStart ~ newLines[0];
                        newLines[$ - 1] = newLines[$ - 1] ~ lineEnd;
                    }
                    else
                    {
                        newLines = [lineStart ~ lineEnd];
                    }

                    this._lines = linesBefore ~ newLines ~ linesAfter;
                }
            }
        }
    }

    private auto getText(string text) const
    {
        import std.algorithm : endsWith;
        import std.array : array;
        import std.conv : to;
        import std.string : lineSplitter;
        import std.typecons : Yes;
        import std.utf : toUTF16;

        auto lines = lineSplitter!(Yes.keepTerminator)(text.toUTF16()).array;

        if (!lines.length || lines[$ - 1].endsWith('\r', '\n'))
        {
            lines ~= "";
        }

        return lines.to!(wchar[][]);
    }
}
