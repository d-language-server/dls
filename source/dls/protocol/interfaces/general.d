module dls.protocol.interfaces.general;

public import dls.protocol.definitions;
import dls.protocol.interfaces.text_document : CompletionItemKind;
import dls.protocol.interfaces.workspace : WorkspaceFolder;

private class WithDynamicRegistration
{
    Nullable!bool dynamicRegistration;
}

class InitializeParams
{
    static enum Trace : string
    {
        off = "off",
        messages = "messages",
        verbose = "verbose"
    }

    Nullable!ulong processId;
    // deprecated Nullable!string rootPath; // TODO: add compatibility
    Nullable!DocumentUri rootUri;
    Nullable!JSONValue initializationOptions;
    ClientCapabilities capabilities = new ClientCapabilities();
    Nullable!Trace trace;
    Nullable!(WorkspaceFolder[]) workspaceFolders;
}

class WorkspaceClientCapabilities
{
    static class WorkspaceEdit
    {
        Nullable!bool documentChanges;
    }

    Nullable!bool applyEdit;
    Nullable!WorkspaceEdit workspaceEdit;
    Nullable!WithDynamicRegistration didChangeConfiguration;
    Nullable!WithDynamicRegistration didChangeWatchedFiles;
    Nullable!WithDynamicRegistration symbol;
    Nullable!WithDynamicRegistration executeCommand;
    Nullable!bool workspaceFolders;
    Nullable!bool configuration;
}

class TextDocumentClientCapabilities
{
    static class Synchronisation
    {
        Nullable!bool dynamicRegistration;
        Nullable!bool willSave;
        Nullable!bool willSaveWaitUntil;
        Nullable!bool didSave;
    }

    static class Completion
    {
        static class CompletionItem
        {
            Nullable!bool snippetSupport;
            Nullable!bool commitCharactersSupport;
            Nullable!(MarkupKind[]) documentationFormat;
        }

        static class CompletionItemKind
        {
            Nullable!(dls.protocol.interfaces.text_document.CompletionItemKind[]) valueSet;
        }

        Nullable!bool dynamicRegistration;
        Nullable!CompletionItem completionItem;
        Nullable!CompletionItemKind completionItemKind;
        Nullable!bool contextSupport;
    }

    Nullable!Synchronisation synchronisation;
    Nullable!Completion completion;
    Nullable!WithDynamicRegistration hover;
    Nullable!WithDynamicRegistration signatureHelp;
    Nullable!WithDynamicRegistration references;
    Nullable!WithDynamicRegistration documentHighlight;
    Nullable!WithDynamicRegistration documentSymbol;
    Nullable!WithDynamicRegistration formatting;
    Nullable!WithDynamicRegistration rangeFormatting;
    Nullable!WithDynamicRegistration onTypeFormatting;
    Nullable!WithDynamicRegistration definition;
    Nullable!WithDynamicRegistration typeDefinition;
    Nullable!WithDynamicRegistration implementation;
    Nullable!WithDynamicRegistration codeAction;
    Nullable!WithDynamicRegistration codeLens;
    Nullable!WithDynamicRegistration documentLink;
    Nullable!WithDynamicRegistration colorProvider;
    Nullable!WithDynamicRegistration rename;
}

class ClientCapabilities
{
    Nullable!WorkspaceClientCapabilities workspace;
    Nullable!TextDocumentClientCapabilities textDocument;
    Nullable!JSONValue experimental;
}

class InitializeResult
{
    ServerCapabilities capabilities = new ServerCapabilities();
}

// deprecated enum InitializeErrorCode // TODO: add compatibility
// {
//     unknownProtocolVersion = 1
// }

class InitializeErrorData
{
    bool retry;
}

enum TextDocumentSyncKind
{
    none = 0,
    full = 1,
    incremental = 2
}

private class OptionsBase
{
    Nullable!bool resolveProvider;
}

class CompletionOptions : OptionsBase
{
    Nullable!(string[]) triggerCharacters;
}

class SignatureHelpOptions
{
    Nullable!(string[]) triggerCharacters;
}

alias CodeLensOptions = OptionsBase;

class DocumentOnTypeFormattingOptions
{
    string firstTriggerCharacter;
    Nullable!(string[]) moreTriggerCharacter;
}

alias DocumentLinkOptions = OptionsBase;

class ExecuteCommandOptions
{
    string[] commands;
}

class SaveOptions
{
    Nullable!bool includeText;
}

class ColorProviderOptions
{
}

class TextDocumentSyncOptions
{
    Nullable!bool openClose;
    Nullable!TextDocumentSyncKind change;
    Nullable!bool willSave;
    Nullable!bool willSaveWaitUntil;
    Nullable!SaveOptions save;
}

class StaticRegistrationOptions
{
    Nullable!string id;
}

class ServerCapabilities
{
    static class Workspace
    {
        static class WorkspaceFolders
        {
            Nullable!bool supported;
            Nullable!JSONValue changeNotifications;
        }

        Nullable!WorkspaceFolders workspaceFolders;
    }

    Nullable!TextDocumentSyncOptions textDocumentSync; // TODO: add TextDocumentSyncKind compatibility
    Nullable!bool hoverProvider;
    Nullable!CompletionOptions completionProvider;
    Nullable!SignatureHelpOptions signatureHelpProvider;
    Nullable!bool definitionProvider;
    Nullable!JSONValue typeDefinitionProvider;
    Nullable!JSONValue implementationProvider;
    Nullable!bool referencesProvider;
    Nullable!bool documentHighlightProvider;
    Nullable!bool documentSymbolProvider;
    Nullable!bool workspaceSymbolProvider;
    Nullable!bool codeActionProvider;
    Nullable!CodeLensOptions codeLensProvider;
    Nullable!bool documentFormattingProvider;
    Nullable!bool documentRangeFormattingProvider;
    Nullable!DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider;
    Nullable!bool renameProvider;
    Nullable!DocumentLinkOptions documentLinkProvider;
    Nullable!JSONValue colorProvider;
    Nullable!ExecuteCommandOptions executeCommandProvider;
    Nullable!Workspace workspace;
    Nullable!JSONValue experimental;
}

class CancelParams
{
    JSONValue id;
}
