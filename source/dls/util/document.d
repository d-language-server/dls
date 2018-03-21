module dls.util.document;

import dls.protocol.definitions;
import dls.protocol.interfaces;

class Document
{
    private static Document[DocumentUri] _documents;
    private wchar[][] _lines;

    static auto opIndex(DocumentUri uri)
    {
        return uri in _documents ? _documents[uri] : null;
    }

    static void open(TextDocumentItem textDocument)
    {
        _documents[textDocument.uri] = new Document(textDocument);
    }

    static void close(TextDocumentIdentifier textDocument)
    {
        if (textDocument.uri in _documents)
        {
            _documents.remove(textDocument.uri);
        }
    }

    static void change(VersionedTextDocumentIdentifier textDocument,
            TextDocumentContentChangeEvent[] events)
    {
        if (textDocument.uri in _documents)
        {
            _documents[textDocument.uri].change(events);
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
        import std.utf : toUTF8;

        return this._lines.join().toUTF8();
    }

    auto bytePosition(Position position)
    {
        import std.algorithm : reduce;
        import std.range : iota;
        import std.utf : codeLength;

        return reduce!((s, i) => s + codeLength!char(this._lines[i]))(cast(size_t) 0,
                iota(position.line)) + codeLength!char(
                this._lines[position.line][0 .. position.character]);
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
