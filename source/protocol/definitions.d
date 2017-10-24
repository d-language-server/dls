module protocol.definitions;

public import std.json;
public import std.typecons;

alias DocumentUri = string;

class Position
{
    uint line;
    uint character;
}

class Range
{
    Position start;
    Position end;
}

class Location
{
    DocumentUri uri;
    Range range;
}

class Diagnostic
{
    Range range;
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
    Range range;
    string newText;
}

class TextDocumentEdit
{
    VersionedTextDocumentIdentifier textDocument;
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
    uint version_;
    string text;
}

class VersionedTextDocumentIdentifier
{
    uint version_;
}

class TextDocumentPositionParams
{
    TextDocumentIdentifier textDocument;
    Position position;
}

class DocumentFilter
{
    Nullable!string languageId;
    Nullable!string scheme;
    Nullable!string pattern;
}

alias DocumentSelector = DocumentFilter[];
