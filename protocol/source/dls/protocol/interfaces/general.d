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

module dls.protocol.interfaces.general;

private class WithDynamicRegistration
{
    import std.typecons : Nullable;

    Nullable!bool dynamicRegistration;
}

final class InitializeParams
{
    import dls.protocol.definitions : DocumentUri;
    import dls.protocol.interfaces.workspace : WorkspaceFolder;
    import std.json : JSONValue;
    import std.typecons : Nullable;

    static enum Trace : string
    {
        off = "off",
        messages = "messages",
        verbose = "verbose"
    }

    static final class InitializationOptions
    {
        static final class Capabilities
        {
            bool hover = true;
            bool completion = true;
            bool definition = true;
            bool typeDefinition = true;
            bool references = true;
            bool documentHighlight = true;
            bool documentSymbol = true;
            bool workspaceSymbol = true;
            bool codeAction = true;
            bool documentFormatting = true;
            bool documentRangeFormatting = true;
            bool documentOnTypeFormatting = true;
            bool rename = true;
        }

        bool autoUpdate = true;
        bool catchErrors = false;
        string logFile = "";
        Capabilities capabilities;

        this()
        {
            this.capabilities = new Capabilities();
        }
    }

    JSONValue processId;
    Nullable!string rootPath;
    Nullable!DocumentUri rootUri;
    Nullable!InitializationOptions initializationOptions;
    ClientCapabilities capabilities;
    Nullable!Trace trace;
    Nullable!(WorkspaceFolder[]) workspaceFolders;

    this()
    {
        this.capabilities = new ClientCapabilities();
    }
}

enum ResourceOperationKind : string
{
    create = "create",
    rename = "rename",
    delete_ = "delete"
}

enum FailureHandlingKind : string
{
    abort = "abort",
    transactional = "transactional",
    textOnlyTransactional = "textOnlyTransactional",
    undo = "undo"
}

final class WorkspaceClientCapabilities
{
    import std.typecons : Nullable;

    static final class WorkspaceEdit
    {
        Nullable!bool documentChanges;
        Nullable!(ResourceOperationKind[]) resourceOperations;
        Nullable!FailureHandlingKind failureHandling;
    }

    static final class Symbol : WithDynamicRegistration
    {
        static final class SymbolKind
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

final class TextDocumentClientCapabilities
{
    import std.typecons : Nullable;

    static final class Synchronisation : WithDynamicRegistration
    {
        Nullable!bool willSave;
        Nullable!bool willSaveWaitUntil;
        Nullable!bool didSave;
    }

    static final class Completion : WithDynamicRegistration
    {
        static final class CompletionItem
        {
            import dls.protocol.definitions : MarkupKind;

            Nullable!bool snippetSupport;
            Nullable!bool commitCharactersSupport;
            Nullable!(MarkupKind[]) documentationFormat;
            Nullable!bool deprecatedSupport;
            Nullable!bool preselectSupport;
        }

        static final class CompletionItemKind
        {
            import dls.protocol.interfaces.text_document : CompletionItemKind;

            Nullable!(CompletionItemKind[]) valueSet;
        }

        Nullable!CompletionItem completionItem;
        Nullable!CompletionItemKind completionItemKind;
        Nullable!bool contextSupport;
    }

    static final class Hover : WithDynamicRegistration
    {
        import dls.protocol.definitions : MarkupKind;

        Nullable!(MarkupKind[]) contentFormat;
    }

    static final class SignatureHelp : WithDynamicRegistration
    {
        static final class SignatureInformation
        {
            import dls.protocol.definitions : MarkupKind;

            Nullable!(MarkupKind[]) documentationFormat;
        }

        Nullable!SignatureInformation signatureHelp;
    }

    static final class DocumentSymbol : WithDynamicRegistration
    {
        static final class SymbolKind
        {
            import dls.protocol.interfaces.text_document : SymbolKind;

            Nullable!(SymbolKind[]) valueSet;
        }

        Nullable!SymbolKind symbolKind;
        Nullable!bool hierarchicalDocumentSymbolSupport;
    }

    static final class CodeAction : WithDynamicRegistration
    {
        static final class CodeActionLiteralSupport
        {
            static final class CodeActionKind
            {
                import dls.protocol.interfaces.text_document : CodeActionKind;

                CodeActionKind[] valueSet;
            }

            CodeActionKind codeActionKind;

            this()
            {
                this.codeActionKind = new CodeActionKind();
            }
        }

        Nullable!CodeActionLiteralSupport codeActionLiteralSupport;
    }

    static final class Rename : WithDynamicRegistration
    {
        Nullable!bool prepareSupport;
    }

    static final class PublishDiagnostics
    {
        Nullable!bool relatedInformation;
    }

    static final class FoldingRange : WithDynamicRegistration
    {
        Nullable!size_t rangeLimit;
        Nullable!bool lineFoldingOnly;
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
    Nullable!CodeAction codeAction;
    Nullable!WithDynamicRegistration codeLens;
    Nullable!WithDynamicRegistration documentLink;
    Nullable!WithDynamicRegistration colorProvider;
    Nullable!Rename rename;
    Nullable!PublishDiagnostics publishDiagnostics;
    Nullable!FoldingRange foldingRange;
}

final class ClientCapabilities
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

    Nullable!WorkspaceClientCapabilities workspace;
    Nullable!TextDocumentClientCapabilities textDocument;
    Nullable!JSONValue experimental;
}

final class InitializeResult
{
    ServerCapabilities capabilities;

    this(ServerCapabilities capabilities = new ServerCapabilities())
    {
        this.capabilities = capabilities;
    }
}

final class InitializeErrorData
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
    import std.typecons : Nullable;

    Nullable!bool resolveProvider;

    this(Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.resolveProvider = resolveProvider;
    }
}

final class CompletionOptions : OptionsBase
{
    import std.typecons : Nullable;

    Nullable!(string[]) triggerCharacters;

    this(Nullable!bool resolveProvider = Nullable!bool.init,
            Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        super(resolveProvider);
        this.triggerCharacters = triggerCharacters;
    }
}

final class SignatureHelpOptions
{
    import std.typecons : Nullable;

    Nullable!(string[]) triggerCharacters;

    this(Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        this.triggerCharacters = triggerCharacters;
    }
}

final class CodeActionOptions
{
    import dls.protocol.interfaces.text_document : CodeActionKind;
    import std.typecons : Nullable;

    Nullable!(CodeActionKind[]) codeActionKinds;

    this(Nullable!(CodeActionKind[]) codeActionKinds = Nullable!(CodeActionKind[]).init)
    {
        this.codeActionKinds = codeActionKinds;
    }
}

alias CodeLensOptions = OptionsBase;

final class DocumentOnTypeFormattingOptions
{
    import std.typecons : Nullable;

    string firstTriggerCharacter;
    Nullable!(string[]) moreTriggerCharacter;

    this(string firstTriggerCharacter = string.init,
            Nullable!(string[]) moreTriggerCharacter = Nullable!(string[]).init)
    {
        this.firstTriggerCharacter = firstTriggerCharacter;
        this.moreTriggerCharacter = moreTriggerCharacter;
    }
}

final class RenameOptions
{
    import std.typecons : Nullable;

    Nullable!bool prepareProvider;

    this(Nullable!bool prepareProvider = Nullable!bool.init)
    {
        this.prepareProvider = prepareProvider;
    }
}

alias DocumentLinkOptions = OptionsBase;

final class ExecuteCommandOptions
{
    string[] commands;

    this(string[] commands = string[].init)
    {
        this.commands = commands;
    }
}

final class SaveOptions
{
    import std.typecons : Nullable;

    Nullable!bool includeText;

    this(Nullable!bool includeText = Nullable!bool.init)
    {
        this.includeText = includeText;
    }
}

final class ColorProviderOptions
{
}

final class FoldingRangeProviderOptions
{
}

final class TextDocumentSyncOptions
{
    import std.typecons : Nullable;

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

final class StaticRegistrationOptions
{
    import std.typecons : Nullable;

    Nullable!string id;

    this(Nullable!string id = Nullable!string.init)
    {
        this.id = id;
    }
}

final class ServerCapabilities
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

    static final class Workspace
    {
        static final class WorkspaceFolders
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
    Nullable!bool typeDefinitionProvider;
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
    Nullable!RenameOptions renameProvider;
    Nullable!DocumentLinkOptions documentLinkProvider;
    Nullable!JSONValue colorProvider;
    Nullable!JSONValue foldingRangeProvider;
    Nullable!ExecuteCommandOptions executeCommandProvider;
    Nullable!Workspace workspace;
    Nullable!JSONValue experimental;
}

final class CancelParams
{
    import std.json : JSONValue;

    JSONValue id;
}
