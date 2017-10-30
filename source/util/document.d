module util.document;

import protocol.definitions;
import protocol.interfaces;
import std.array;
import std.conv;
import std.string;
import std.utf;
import util.json;

shared class Document
{
    private static shared(Document[DocumentUri]) _documents;
    private DocumentUri _uri;
    private wchar[][] _lines;

    static auto opIndex(DocumentUri uri)
    {
        return uri in _documents ? _documents[uri] : null;
    }

    static void open(TextDocumentItem textDocument)
    {
        _documents[textDocument.uri] = new shared Document(textDocument);
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

    @property auto uri() const
    {
        return this._uri;
    }

    @property auto lines() const
    {
        return this._lines;
    }

    this(TextDocumentItem textDocument)
    {
        this._uri = textDocument.uri;
        this._lines = this.getText(textDocument.text);
    }

    string toString() const
    {
        return this._lines.join().to!string;
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
        auto lines = cast(shared(wchar[][])) lineSplitter!(Yes.keepTerminator)(text.toUTF16())
            .array;

        if (!lines.length || lines[$ - 1].endsWith('\r', '\n'))
        {
            lines ~= cast(shared(wchar[])) "";
        }

        return lines;
    }
}
