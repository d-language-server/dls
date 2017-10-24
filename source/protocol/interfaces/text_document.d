module protocol.interfaces.text_document;

public import protocol.definitions;

class PublishDiagnosticsParams
{
    DocumentUri uri;
    Diagnostic[] diagnostics;
}

class DidOpenTextDocumentParams
{
    TextDocumentItem textDocument;
}

class DidChangeTextDocumentParams
{
    VersionedTextDocumentIdentifier textDocument;
    TextDocumentContentChangeEvent[] contentChanges;
}

class TextDocumentContentChangeEvent
{
    Nullable!Range range;
    Nullable!size_t rangeLength;
    string text;
}

private class ParamsBase
{
    TextDocumentIdentifier textDocument;
}

class WillSaveTextDocumentParams : ParamsBase
{
    TextDocumentSaveReason reason;
}

enum TextDocumentSaveReason
{
    manual = 1,
    afterDelay = 2,
    focusOut = 3
}

class DidSaveTextDocumentParams : ParamsBase
{
    Nullable!string text;
}

alias DidCloseTextDocumentParams = ParamsBase;

class CompletionList
{
    bool isIncomplete;
    CompletionItem[] items;
}

enum InsertTextFormat
{
    plainText = 1,
    snippet = 2
}

class CompletionItem
{
    string label;
    Nullable!CompletionItemKind kind;
    Nullable!string detail;
    Nullable!string documentation;
    Nullable!string sortText;
    Nullable!string filtrText;
    Nullable!string insertText;
    Nullable!InsertTextFormat insertTextFormat;
    Nullable!TextEdit textEdit;
    Nullable!(TextEdit[]) additionalTextEdits;
    Nullable!(string[]) commitCharacters;
    Nullable!Command command;
    Nullable!JSONValue data;
}

enum CompletionItemKind
{
    text = 1,
    method = 2,
    function_ = 3,
    constructor = 4,
    field = 5,
    variable = 6,
    class_ = 7,
    interface_ = 8,
    module_ = 9,
    property = 10,
    unit = 11,
    value = 12,
    enum_ = 13,
    keyword = 14,
    snippet = 15,
    color = 16,
    file = 17,
    reference = 18
}

class Hover
{
    JSONValue contents;
    Nullable!Range range;
}

class SignatureHelp
{
    SignatureInformation[] signatures;
    Nullable!double activeSignature;
    Nullable!double activeParameter;
}

private class InformationBase
{
    string label;
    Nullable!string documentation;
}

class SignatureInformation : InformationBase
{
    Nullable!(ParameterInformation[]) parameters;
}

alias ParameterInformation = InformationBase;

class ReferenceParams : TextDocumentPositionParams
{
    ReferenceContext context;
}

class ReferenceContext
{
    bool includeDeclaration;
}

class DocumentHighlight
{
    Range range;
    Nullable!DocumentHighlightKind kind;
}

enum DocumentHighlightKind
{
    text = 1,
    read = 2,
    write = 3
}

alias DocumentSymbolParams = ParamsBase;

class SymbolInformation
{
    string name;
    SymbolKind kind;
    Location location;
    Nullable!string containerName;
}

enum SymbolKind
{
    file = 1,
    module_ = 2,
    namespace = 3,
    package_ = 4,
    class_ = 5,
    method = 6,
    property = 7,
    field = 8,
    constructor = 9,
    enum_ = 10,
    interface_ = 11,
    function_ = 12,
    variable = 13,
    constant = 14,
    string_ = 15,
    number = 16,
    boolean = 17,
    array = 18
}

class DocumentFormattingParams : ParamsBase
{
    FormattingOptions options;
}

class FormattingOptions
{
    uint tabSize;
    bool insertSpaces;
}

class DocumentRangeFormattingParams : DocumentFormattingParams
{
    Range range;
}

class DocumentOnTypeFormattingParams : DocumentFormattingParams
{
    Position position;
    string ch;
}

class CodeActionParams : ParamsBase
{
    Range range;
    CodeActionContext context;
}

class CodeActionContext
{
    Diagnostic[] diagnostics;
}

alias CodeLensParams = ParamsBase;

class CodeLens
{
    Range range;
    Nullable!Command command;
    Nullable!JSONValue data;
}

alias DocumentLinkParams = ParamsBase;

class DocumentLink
{
    Range range;
    Nullable!DocumentUri target;
}

class RenameParams : ParamsBase
{
    Position position;
    string newName;
}
