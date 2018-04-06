module dls.protocol.definitions;

public import std.json : JSONValue;
public import std.typecons : Nullable, nullable;
import dls.util.constructor : Constructor;

alias DocumentUri = string;

class Position
{
    size_t line;
    size_t character;
}

class Range
{
    Position start;
    Position end;

    mixin Constructor!Range;
}

class Location
{
    DocumentUri uri;
    Range range;

    mixin Constructor!Location;
}

class Diagnostic
{
    Range range;
    Nullable!DiagnosticSeverity severity;
    Nullable!JSONValue code;
    Nullable!string source;
    string message;
    Nullable!(DiagnosticRelatedInformation[]) relatedInformation;

    mixin Constructor!Diagnostic;
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

    mixin Constructor!TextEdit;
}

class TextDocumentEdit
{
    VersionedTextDocumentIdentifier textDocument;
    TextEdit[] edits;

    mixin Constructor!TextDocumentEdit;
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
    TextDocumentIdentifier textDocument;
    Position position;

    mixin Constructor!TextDocumentPositionParams;
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
    MarkupKind kind;
    string value;
}
