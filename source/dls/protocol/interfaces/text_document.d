module dls.protocol.interfaces.text_document;

import dls.protocol.definitions;
import dls.protocol.interfaces.client : TextDocumentRegistrationOptions;
import dls.protocol.interfaces.general : TextDocumentSyncKind;
import dls.util.constructor : Constructor;
import std.json : JSONValue;
import std.typecons : Nullable;

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

    this(TextDocumentSyncKind syncKind = TextDocumentSyncKind.init)
    {
        this.syncKind = syncKind;
    }
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

    this(Nullable!bool includeText = Nullable!bool.init)
    {
        this.includeText = includeText;
    }
}

alias DidCloseTextDocumentParams = ParamsBase;

class PublishDiagnosticsParams
{
    DocumentUri uri;
    Diagnostic[] diagnostics;

    this(DocumentUri uri = DocumentUri.init, Diagnostic[] diagnostics = Diagnostic[].init)
    {
        this.uri = uri;
        this.diagnostics = diagnostics;
    }
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

    this(bool isIncomplete = bool.init, CompletionItem[] items = CompletionItem[].init)
    {
        this.isIncomplete = isIncomplete;
        this.items = items;
    }
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
    Nullable!MarkupContent documentation;
    Nullable!bool deprecated_;
    Nullable!string sortText;
    Nullable!string filterText;
    Nullable!string insertText;
    Nullable!InsertTextFormat insertTextFormat;
    Nullable!TextEdit textEdit;
    Nullable!(TextEdit[]) additionalTextEdits;
    Nullable!(string[]) commitCharacters;
    Nullable!Command command;
    Nullable!JSONValue data;

    this(string label = string.init, Nullable!CompletionItemKind kind = Nullable!CompletionItemKind.init,
            Nullable!string detail = Nullable!string.init,
            Nullable!MarkupContent documentation = Nullable!MarkupContent.init,
            Nullable!bool deprecated_ = Nullable!bool.init, Nullable!string sortText = Nullable!string.init,
            Nullable!string filterText = Nullable!string.init, Nullable!string insertText = Nullable!string.init,
            Nullable!InsertTextFormat insertTextFormat = Nullable!InsertTextFormat.init,
            Nullable!TextEdit textEdit = Nullable!TextEdit.init,
            Nullable!(TextEdit[]) additionalTextEdits = Nullable!(TextEdit[])
            .init, Nullable!(string[]) commitCharacters = Nullable!(string[])
            .init, Nullable!Command command = Nullable!Command.init,
            Nullable!JSONValue data = Nullable!JSONValue.init)
    {
        this.label = label;
        this.kind = kind;
        this.detail = detail;
        this.documentation = documentation;
        this.deprecated_ = deprecated_;
        this.sortText = sortText;
        this.filterText = filterText;
        this.insertText = insertText;
        this.insertTextFormat = insertTextFormat;
        this.textEdit = textEdit;
        this.additionalTextEdits = additionalTextEdits;
        this.commitCharacters = commitCharacters;
        this.command = command;
        this.data = data;
    }
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

    this(Nullable!(string[]) triggerCharacters = Nullable!(string[]).init,
            Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.triggerCharacters = triggerCharacters;
        this.resolveProvider = resolveProvider;
    }
}

class Hover
{
    MarkupContent contents;
    Nullable!Range range;

    this(MarkupContent contents = MarkupContent.init, Nullable!Range range = Nullable!Range.init)
    {
        this.contents = contents;
        this.range = range;
    }
}

class SignatureHelp
{
    SignatureInformation[] signatures;
    Nullable!double activeSignature;
    Nullable!double activeParameter;

    this(SignatureInformation[] signatures = SignatureInformation[].init,
            Nullable!double activeSignature = Nullable!double.init,
            Nullable!double activeParameter = Nullable!double.init)
    {
        this.signatures = signatures;
        this.activeSignature = activeSignature;
        this.activeParameter = activeParameter;
    }
}

private class InformationBase
{
    string label;
    Nullable!string documentation;
}

class SignatureInformation : InformationBase
{
    Nullable!(ParameterInformation[]) parameters;

    this(Nullable!(ParameterInformation[]) parameters = Nullable!(ParameterInformation[]).init)
    {
        this.parameters = parameters;
    }
}

alias ParameterInformation = InformationBase;

class SignatureHelpRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!(string[]) triggerCharacters;

    this(Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        this.triggerCharacters = triggerCharacters;
    }
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

    this(Range range = new Range(),
            Nullable!DocumentHighlightKind kind = Nullable!DocumentHighlightKind.init)
    {
        this.range = range;
        this.kind = kind;
    }
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

    this(string name = string.init, SymbolKind kind = SymbolKind.init,
            Location location = new Location(),
            Nullable!string containerName = Nullable!string.init)
    {
        this.name = name;
        this.kind = kind;
        this.location = location;
        this.containerName = containerName;
    }
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

    this(Range range = new Range(), Nullable!Command command = Nullable!Command.init,
            Nullable!JSONValue data = Nullable!JSONValue.init)
    {
        this.range = range;
        this.command = command;
        this.data = data;
    }
}

class CodeLensRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!bool resolveProvider;

    this(Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.resolveProvider = resolveProvider;
    }
}

alias DocumentLinkParams = ParamsBase;

class DocumentLink
{
    Range range;
    Nullable!DocumentUri target;

    this(Range range = new Range(), Nullable!DocumentUri target = Nullable!DocumentUri.init)
    {
        this.range = range;
        this.target = target;
    }
}

class DocumentLinkRegistrationOptions : TextDocumentRegistrationOptions
{
    Nullable!bool resolveProvider;

    this(Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.resolveProvider = resolveProvider;
    }
}

class DocumentColorParams
{
    TextDocumentIdentifier textDocument;

    mixin Constructor!DocumentColorParams;
}

class ColorInformation
{
    Range range;
    Color color;

    this(Range range = new Range(), Color color = new Color())
    {
        this.range = range;
        this.color = color;
    }
}

class Color
{
    float red;
    float green;
    float blue;
    float alpha;

    this(float red = 0, float green = 0, float blue = 0, float alpha = 0)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }
}

class ColorPresentationParams
{
    TextDocumentIdentifier textDocument;
    Color colorInfo;
    Range range;

    mixin Constructor!ColorPresentationParams;
}

class ColorPresentation
{
    string label;
    Nullable!TextEdit textEdit;
    Nullable!(TextEdit[]) additionalTextEdits;

    this(string label = string.init, Nullable!TextEdit textEdit = Nullable!TextEdit.init,
            Nullable!(TextEdit[]) additionalTextEdits = Nullable!(TextEdit[]).init)
    {
        this.label = label;
        this.textEdit = textEdit;
        this.additionalTextEdits = additionalTextEdits;
    }
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

    this(string firstTriggerCharacter = string.init,
            Nullable!(string[]) moreTriggerCharacter = Nullable!(string[]).init)
    {
        this.firstTriggerCharacter = firstTriggerCharacter;
        this.moreTriggerCharacter = moreTriggerCharacter;
    }
}

class RenameParams : ParamsBase
{
    Position position;
    string newName;

    mixin Constructor!RenameParams;
}
