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

module dls.protocol.definitions;

alias DocumentUri = string;

class Position
{
    size_t line;
    size_t character;

    this(size_t line = size_t.init, size_t character = size_t.init)
    {
        this.line = line;
        this.character = character;
    }
}

class Range
{
    Position start;
    Position end;

    this(Position start = new Position(), Position end = new Position())
    {
        this.start = start;
        this.end = end;
    }
}

class Location
{
    DocumentUri uri;
    Range range;

    this(DocumentUri uri = DocumentUri.init, Range range = new Range())
    {
        this.uri = uri;
        this.range = range;
    }
}

class Diagnostic
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

    Range range;
    string message;
    Nullable!DiagnosticSeverity severity;
    Nullable!JSONValue code;
    Nullable!string source;
    Nullable!(DiagnosticRelatedInformation[]) relatedInformation;

    this(Range range = new Range(), string message = string.init,
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

enum DiagnosticSeverity : uint
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

    this(Location location = new Location(), string message = string.init)
    {
        this.location = location;
        this.message = message;
    }
}

class Command
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

    string title;
    string command;
    Nullable!(JSONValue[]) arguments;

    this(string title = string.init, string command = string.init,
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

    this(Range range = new Range(), string newText = string.init)
    {
        this.range = range;
        this.newText = newText;
    }
}

class TextDocumentEdit
{
    VersionedTextDocumentIdentifier textDocument;
    TextEdit[] edits;

    this(VersionedTextDocumentIdentifier textDocument = new VersionedTextDocumentIdentifier(),
            TextEdit[] edits = TextEdit[].init)
    {
        this.textDocument = textDocument;
        this.edits = edits;
    }
}

class CreateFileOptions
{
    import std.typecons : Nullable;

    Nullable!bool overwrite;
    Nullable!bool ignoreIfExists;

    this(Nullable!bool overwrite = Nullable!bool.init,
            Nullable!bool ignoreIfExists = Nullable!bool.init)
    {
        this.overwrite = overwrite;
        this.ignoreIfExists = ignoreIfExists;
    }
}

class CreateFile
{
    import std.typecons : Nullable;

    immutable string kind = "create";
    string uri;
    Nullable!CreateFileOptions options;

    this(string uri = string.init,
            Nullable!CreateFileOptions options = Nullable!CreateFileOptions.init)
    {
        this.uri = uri;
        this.options = options;
    }
}

class RenameFileOptions
{
    import std.typecons : Nullable;

    Nullable!bool overwrite;
    Nullable!bool ignoreIfExists;

    this(Nullable!bool overwrite = Nullable!bool.init,
            Nullable!bool ignoreIfExists = Nullable!bool.init)
    {
        this.overwrite = overwrite;
        this.ignoreIfExists = ignoreIfExists;
    }
}

class RenameFile
{
    import std.typecons : Nullable;

    immutable string kind = "rename";
    string oldUri;
    string newUri;
    Nullable!RenameFileOptions options;

    this(string oldUri = string.init, string newUri = string.init,
            Nullable!RenameFileOptions options = Nullable!RenameFileOptions.init)
    {
        this.oldUri = oldUri;
        this.newUri = newUri;
        this.options = options;
    }
}

class DeleteFileOptions
{
    import std.typecons : Nullable;

    Nullable!bool recursive;
    Nullable!bool ignoreIfExists;

    this(Nullable!bool recursive = Nullable!bool.init,
            Nullable!bool ignoreIfExists = Nullable!bool.init)
    {
        this.recursive = recursive;
        this.ignoreIfExists = ignoreIfExists;
    }
}

class DeleteFile
{
    import std.typecons : Nullable;

    immutable string kind = "delete";
    string uri;
    Nullable!DeleteFileOptions options;

    this(string uri = string.init,
            Nullable!DeleteFileOptions options = Nullable!DeleteFileOptions.init)
    {
        this.uri = uri;
        this.options = options;
    }
}

class WorkspaceEdit
{
    import std.typecons : Nullable;

    Nullable!(TextEdit[][string]) changes;
    Nullable!(TextDocumentEdit[]) documentChanges; // (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[]

    this(Nullable!(TextEdit[][string]) changes = Nullable!(TextEdit[][string])
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

    this(DocumentUri uri = DocumentUri.init)
    {
        this.uri = uri;
    }
}

class TextDocumentItem : TextDocumentIdentifier
{
    string languageId;
    long version_;
    string text;

    this(DocumentUri uri = DocumentUri.init, string languageId = string.init,
            long version_ = long.init, string text = string.init)
    {
        super(uri);
        this.languageId = languageId;
        this.version_ = version_;
        this.text = text;
    }
}

class VersionedTextDocumentIdentifier : TextDocumentIdentifier
{
    import std.json : JSONValue;

    JSONValue version_;

    this(DocumentUri uri = DocumentUri.init, JSONValue version_ = JSONValue.init)
    {
        super(uri);
        this.version_ = version_;
    }
}

class TextDocumentPositionParams
{
    import dls.util.constructor : Constructor;

    TextDocumentIdentifier textDocument;
    Position position;

    mixin Constructor!TextDocumentPositionParams;
}

class DocumentFilter
{
    import std.typecons : Nullable;

    Nullable!string languageId;
    Nullable!string scheme;
    Nullable!string pattern;

    this(Nullable!string languageId = Nullable!string.init,
            Nullable!string scheme = Nullable!string.init,
            Nullable!string pattern = Nullable!string.init)
    {
        this.languageId = languageId;
        this.scheme = scheme;
        this.pattern = pattern;
    }
}

alias DocumentSelector = DocumentFilter[];

enum MarkupKind : string
{
    plaintext = "plaintext",
    markdown = "markdown"
}

class MarkupContent
{
    MarkupKind kind;
    string value;

    this(MarkupKind kind = MarkupKind.init, string value = string.init)
    {
        this.kind = kind;
        this.value = value;
    }
}
