module dls.protocol.definitions;

import std.json : JSONValue;
import std.typecons : Nullable, nullable;
import dls.util.constructor : Constructor;

alias DocumentUri = string;

class Position
{
    size_t line;
    size_t character;

    @safe this(size_t line = size_t.init, size_t character = size_t.init)
    {
        this.line = line;
        this.character = character;
    }
}

class Range
{
    Position start;
    Position end;

    @safe this(Position start = new Position(), Position end = new Position())
    {
        this.start = start;
        this.end = end;
    }
}

class Location
{
    DocumentUri uri;
    Range range;

    @safe this(DocumentUri uri = DocumentUri.init, Range range = new Range())
    {
        this.uri = uri;
        this.range = range;
    }
}

class Diagnostic
{
    Range range;
    string message;
    Nullable!DiagnosticSeverity severity;
    Nullable!JSONValue code;
    Nullable!string source;
    Nullable!(DiagnosticRelatedInformation[]) relatedInformation;

    @safe this(Range range = new Range(), string message = string.init,
            Nullable!DiagnosticSeverity severity = Nullable!DiagnosticSeverity.init,
            Nullable!JSONValue code = Nullable!JSONValue.init,
            Nullable!string source = Nullable!string.init,
            Nullable!(DiagnosticRelatedInformation[]) relatedInformation = Nullable!(
                DiagnosticRelatedInformation[]).init)
    {
        this.range = range;
        this.message = message;
        this.severity = severity;
        this.code = code;
        this.source = source;
        this.relatedInformation = relatedInformation;
    }
}

enum DiagnosticSeverity
{
    error = 1,
    warning = 2,
    information = 3,
    hint = 4
}

class DiagnosticRelatedInformation
{
    Location location;
    string message;

    @safe this(Location location = new Location(), string message = string.init)
    {
        this.location = location;
        this.message = message;
    }
}

class Command
{
    string title;
    string command;
    Nullable!(JSONValue[]) arguments;

    @safe this(string title = string.init, string command = string.init,
            Nullable!(JSONValue[]) arguments = Nullable!(JSONValue[]).init)
    {
        this.title = title;
        this.command = command;
        this.arguments = arguments;
    }
}

class TextEdit
{
    Range range;
    string newText;

    @safe this(Range range = new Range(), string newText = string.init)
    {
        this.range = range;
        this.newText = newText;
    }
}

class TextDocumentEdit
{
    VersionedTextDocumentIdentifier textDocument;
    TextEdit[] edits;

    @safe this(VersionedTextDocumentIdentifier textDocument = new VersionedTextDocumentIdentifier(),
            TextEdit[] edits = TextEdit[].init)
    {
        this.textDocument = textDocument;
        this.edits = edits;
    }
}

class WorkspaceEdit
{
    Nullable!((TextEdit[])[string]) changes;
    Nullable!(TextDocumentEdit[]) documentChanges;

    @safe this(Nullable!((TextEdit[])[string]) changes = Nullable!((TextEdit[])[string])
            .init, Nullable!(TextDocumentEdit[]) documentChanges = Nullable!(
                TextDocumentEdit[]).init)
    {
        this.changes = changes;
        this.documentChanges = documentChanges;
    }
}

class TextDocumentIdentifier
{
    DocumentUri uri;
}

class TextDocumentItem
{
    DocumentUri uri;
    string languageId;
    ulong version_;
    string text;
}

class VersionedTextDocumentIdentifier : TextDocumentIdentifier
{
    ulong version_;
}

class TextDocumentPositionParams
{
    TextDocumentIdentifier textDocument;
    Position position;

    mixin Constructor!TextDocumentPositionParams;
}

class DocumentFilter
{
    Nullable!string languageId;
    Nullable!string scheme;
    Nullable!string pattern;

    @safe this(Nullable!string languageId = Nullable!string.init,
            Nullable!string scheme = Nullable!string.init,
            Nullable!string pattern = Nullable!string.init)
    {
        this.languageId = languageId;
        this.scheme = scheme;
        this.pattern = pattern;
    }
}

alias DocumentSelector = DocumentFilter[];

enum MarkupKind
{
    plaintext = "plaintext",
    markdown = "markdown"
}

class MarkupContent
{
    MarkupKind kind;
    string value;

    @safe this(MarkupKind kind = MarkupKind.init, string value = string.init)
    {
        this.kind = kind;
        this.value = value;
    }
}
