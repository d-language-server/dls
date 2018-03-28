module dls.protocol.interfaces.text_document;

public import dls.protocol.definitions;
import dls.protocol.interfaces.client : TextDocumentRegistrationOptions;
import dls.protocol.interfaces.general : TextDocumentSyncKind;
import dls.util.constructor : Constructor;

class DidOpenTextDocumentParams
{
    TextDocumentItem textDocument;

    mixin Constructor!DidOpenTextDocumentParams;
}

class DidChangeTextDocumentParams
{
    VersionedTextDocumentIdentifier textDocument;
    TextDocumentContentChangeEvent[] contentChanges;

    mixin Constructor!DidChangeTextDocumentParams;
}

class TextDocumentContentChangeEvent
{
    Nullable!Range range;
    Nullable!size_t rangeLength;
    string text;
}

class TextDocumentChangeRegistrationOptions : TextDocumentRegistrationOptions
{
    TextDocumentSyncKind syncKind;
}

private class ParamsBase
{
    TextDocumentIdentifier textDocument;

    mixin Constructor!ParamsBase;
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

class TextDocumentSaveRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!bool includeText;
}

alias DidCloseTextDocumentParams = ParamsBase;

class PublishDiagnosticsParams
{
    DocumentUri uri;
    Diagnostic[] diagnostics;
}

class CompletionParams : TextDocumentPositionParams
{
    Nullable!CompletionContext context;
}

class CompletionContext
{
    CompletionTriggerKind triggerKind;
    Nullable!string triggerCharacter;
}

enum CompletionTriggerKind
{
    invoked = 1,
    triggerCharacter = 2,
    triggerForIncompleteCompletions = 3
}

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
    Nullable!string filterText;
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
    reference = 18,
    folder = 19,
    enumMember = 20,
    constant = 21,
    struct_ = 22,
    event = 23,
    operator = 24,
    typeParameter = 25
}

class CompletionRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!(string[]) triggerCharacters;
    Nullable!bool resolveProvider;
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

class SignatureHelpRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!(string[]) triggerCharacters;
}

class ReferenceParams : TextDocumentPositionParams
{
    ReferenceContext context;

    mixin Constructor!ReferenceParams;
}

class ReferenceContext
{
    bool includeDeclaration;
}

class DocumentHighlight
{
    Range range;
    Nullable!DocumentHighlightKind kind;

    mixin Constructor!DocumentHighlight;
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

    mixin Constructor!SymbolInformation;
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
    array = 18,
    object = 19,
    key = 20,
    null_ = 21,
    enumMember = 22,
    struct_ = 23,
    event = 24,
    operator = 25,
    typeParameter = 26
}

class CodeActionParams : ParamsBase
{
    Range range;
    CodeActionContext context;

    mixin Constructor!CodeActionParams;
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

    mixin Constructor!CodeLens;
}

class CodeLensRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!bool resolveProvider;
}

alias DocumentLinkParams = ParamsBase;

class DocumentLink
{
    Range range;
    Nullable!DocumentUri target;

    mixin Constructor!DocumentLink;
}

class DocumentLinkRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!bool resolveProvider;
}

class DocumentColorParams
{
    TextDocumentIdentifier textDocument;
}

class ColorInformation
{
    Range range;
    Color color;
}

class Color
{
    float red;
    float green;
    float blue;
    float alpha;
}

class ColorPresentationParams
{
    TextDocumentIdentifier textDocument;
    Color colorInfo;
    Range range;
}

class ColorPresentation
{
    string label;
    Nullable!TextEdit textEdit;
    Nullable!(TextEdit[]) additionalTextEdits;
}

class DocumentFormattingParams : ParamsBase
{
    FormattingOptions options;

    mixin Constructor!DocumentFormattingParams;
}

class FormattingOptions
{
    size_t tabSize;
    bool insertSpaces;
}

class DocumentRangeFormattingParams : DocumentFormattingParams
{
    Range range;

    mixin Constructor!DocumentRangeFormattingParams;
}

class DocumentOnTypeFormattingParams : DocumentFormattingParams
{
    Position position;
    string ch;

    mixin Constructor!DocumentOnTypeFormattingParams;
}

class DocumentOnTypeFormattingRegistrationOptions : TextDocumentRegistrationOptions
{
    string firstTriggerCharacter;
    Nullable!(string[]) moreTriggerCharacter;
}

class RenameParams : ParamsBase
{
    Position position;
    string newName;

    mixin Constructor!RenameParams;
}
