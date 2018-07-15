module dls.protocol.interfaces.general;

import dls.protocol.definitions : MarkupKind;
import dls.protocol.interfaces.workspace : WorkspaceFolder;
import dls.util.constructor : Constructor;
import std.json : JSONValue;
import std.typecons : Nullable;

private class WithDynamicRegistration
{
    Nullable!bool dynamicRegistration;
}

class InitializeParams
{
    import dls.protocol.definitions : DocumentUri;
    import dls.protocol.interfaces.workspace : WorkspaceFolder;

    static enum Trace : string
    {
        off = "off",
        messages = "messages",
        verbose = "verbose"
    }

    static class InitializationOptions
    {
        static class Capabilities
        {
            bool completion = true;
            bool hover = true;
            bool documentFormatting = true;
            bool definition = true;
            bool documentHighlight = true;
            bool documentSymbol = true;
            bool workspaceSymbol = true;
        }

        Capabilities capabilities;

        mixin Constructor!InitializationOptions;
    }

    Nullable!ulong processId;
    Nullable!string rootPath;
    Nullable!DocumentUri rootUri;
    Nullable!InitializationOptions initializationOptions;
    ClientCapabilities capabilities;
    Nullable!Trace trace;
    Nullable!(WorkspaceFolder[]) workspaceFolders;

    mixin Constructor!InitializeParams;
}

class WorkspaceClientCapabilities
{
    static class WorkspaceEdit
    {
        Nullable!bool documentChanges;
    }

    static class Symbol : WithDynamicRegistration
    {
        static class SymbolKind
        {
            import dls.protocol.interfaces.text_document : SymbolKind;

            Nullable!(SymbolKind[]) valueSet;
        }

        Nullable!SymbolKind symbolKind;
    }

    Nullable!bool applyEdit;
    Nullable!WorkspaceEdit workspaceEdit;
    Nullable!WithDynamicRegistration didChangeConfiguration;
    Nullable!WithDynamicRegistration didChangeWatchedFiles;
    Nullable!Symbol symbol;
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
            Nullable!bool deprecatedSupport;
            Nullable!bool preselectSupport;
        }

        static class CompletionItemKind
        {
            import dls.protocol.interfaces.text_document : CompletionItemKind;

            Nullable!(CompletionItemKind[]) valueSet;
        }

        Nullable!bool dynamicRegistration;
        Nullable!CompletionItem completionItem;
        Nullable!CompletionItemKind completionItemKind;
        Nullable!bool contextSupport;
    }

    static class Hover : WithDynamicRegistration
    {
        Nullable!(MarkupKind[]) contentFormat;
    }

    static class SignatureHelp : WithDynamicRegistration
    {
        static class SignatureInformation
        {
            Nullable!(MarkupKind[]) documentationFormat;
        }

        Nullable!SignatureInformation signatureHelp;
    }

    static class DocumentSymbol : WithDynamicRegistration
    {
        static class SymbolKind
        {
            import dls.protocol.interfaces.text_document : SymbolKind;

            Nullable!(SymbolKind[]) valueSet;
        }

        Nullable!SymbolKind symbolKind;
    }

    static class CodeAction : WithDynamicRegistration
    {
        static class CodeActionLiteralSupport
        {
            static class CodeActionKind
            {
                import dls.protocol.interfaces.text_document : CodeActionKind;

                CodeActionKind[] valueSet;
            }

            CodeActionKind codeActionKind;
        }

        Nullable!CodeActionLiteralSupport codeActionLiteralSupport;
    }

    Nullable!Synchronisation synchronisation;
    Nullable!Completion completion;
    Nullable!Hover hover;
    Nullable!SignatureHelp signatureHelp;
    Nullable!WithDynamicRegistration references;
    Nullable!WithDynamicRegistration documentHighlight;
    Nullable!DocumentSymbol documentSymbol;
    Nullable!WithDynamicRegistration formatting;
    Nullable!WithDynamicRegistration rangeFormatting;
    Nullable!WithDynamicRegistration onTypeFormatting;
    Nullable!WithDynamicRegistration definition;
    Nullable!WithDynamicRegistration typeDefinition;
    Nullable!WithDynamicRegistration implementation;
    Nullable!WithDynamicRegistration codeAction; // don't use CodeAction yet
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
    ServerCapabilities capabilities;

    this(ServerCapabilities capabilities = new ServerCapabilities())
    {
        this.capabilities = capabilities;
    }
}

class InitializeErrorData
{
    bool retry;
}

enum TextDocumentSyncKind : uint
{
    none = 0,
    full = 1,
    incremental = 2
}

private class OptionsBase
{
    Nullable!bool resolveProvider;

    this(Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.resolveProvider = resolveProvider;
    }
}

class CompletionOptions : OptionsBase
{
    Nullable!(string[]) triggerCharacters;

    this(Nullable!bool resolveProvider = Nullable!bool.init,
            Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        super(resolveProvider);
        this.triggerCharacters = triggerCharacters;
    }
}

class SignatureHelpOptions
{
    Nullable!(string[]) triggerCharacters;

    this(Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        this.triggerCharacters = triggerCharacters;
    }
}

alias CodeLensOptions = OptionsBase;

class DocumentOnTypeFormattingOptions
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

alias DocumentLinkOptions = OptionsBase;

class ExecuteCommandOptions
{
    string[] commands;

    this(string[] commands = string[].init)
    {
        this.commands = commands;
    }
}

class SaveOptions
{
    Nullable!bool includeText;

    this(Nullable!bool includeText = Nullable!bool.init)
    {
        this.includeText = includeText;
    }
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

    this(Nullable!bool openClose = Nullable!bool.init,
            Nullable!TextDocumentSyncKind change = Nullable!TextDocumentSyncKind.init,
            Nullable!bool willSave = Nullable!bool.init, Nullable!bool willSaveWaitUntil = Nullable!bool.init,
            Nullable!SaveOptions save = Nullable!SaveOptions.init)
    {
        this.openClose = openClose;
        this.change = change;
        this.willSave = willSave;
        this.willSaveWaitUntil = willSaveWaitUntil;
        this.save = save;
    }
}

class StaticRegistrationOptions
{
    Nullable!string id;

    this(Nullable!string id = Nullable!string.init)
    {
        this.id = id;
    }
}

class ServerCapabilities
{
    static class Workspace
    {
        static class WorkspaceFolders
        {
            Nullable!bool supported;
            Nullable!JSONValue changeNotifications;

            this(Nullable!bool supported = Nullable!bool.init,
                    Nullable!JSONValue changeNotifications = Nullable!JSONValue.init)
            {
                this.supported = supported;
                this.changeNotifications = changeNotifications;
            }
        }

        Nullable!WorkspaceFolders workspaceFolders;

        this(Nullable!WorkspaceFolders workspaceFolders = Nullable!WorkspaceFolders.init)
        {
            this.workspaceFolders = workspaceFolders;
        }
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
