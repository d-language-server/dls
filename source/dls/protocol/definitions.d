module dls.protocol.definitions;

public import std.json;
public import std.typecons;

alias DocumentUri = string;

class Position
{
    size_t line;
    size_t character;
}

class Range
{
    Position start = new Position();
    Position end = new Position();
}

class Location
{
    DocumentUri uri;
    Range range = new Range();
}

class Diagnostic
{
    Range range = new Range();
    Nullable!DiagnosticSeverity severity;
    Nullable!JSONValue code;
    Nullable!string source;
    string message;
}

enum DiagnosticSeverity
{
    error = 1,
    warning = 2,
    information = 3,
    hint = 4
}

class Command
{
    string title;
    string command;
    Nullable!(JSONValue[]) arguments;
}

class TextEdit
{
    Range range = new Range();
    string newText;
}

class TextDocumentEdit
{
    VersionedTextDocumentIdentifier textDocument = new VersionedTextDocumentIdentifier();
    TextEdit[] edits;
}

class WorkspaceEdit
{
    Nullable!(TextEdit[string]) changes;
    Nullable!(TextDocumentEdit[]) documentChanges;
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
    TextDocumentIdentifier textDocument = new TextDocumentIdentifier();
    Position position = new Position();
}

class DocumentFilter
{
    Nullable!string languageId;
    Nullable!string scheme;
    Nullable!string pattern;
}

alias DocumentSelector = DocumentFilter[];

enum MarkupKind
{
    plaintext = "plaintext",
    markdown = "markdown"
}

class MarkupContent
{
    MarkupContent content;
    string value;
}
