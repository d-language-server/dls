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

class InitializeParams
{
    import dls.protocol.definitions : DocumentUri;
    import dls.protocol.interfaces.workspace : WorkspaceFolder;
    import dls.util.constructor : Constructor;
    import std.typecons : Nullable;

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
            bool hover = true;
            bool completion = true;
            bool definition = true;
            bool typeDefinition = true;
            bool references = true;
            bool documentHighlight = true;
            bool documentSymbol = true;
            bool workspaceSymbol = true;
            bool documentFormatting = true;
            bool rename = true;
        }

        bool autoUpdate = true;
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
    import std.typecons : Nullable;

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
    import std.typecons : Nullable;

    static class Synchronisation : WithDynamicRegistration
    {
        Nullable!bool willSave;
        Nullable!bool willSaveWaitUntil;
        Nullable!bool didSave;
    }

    static class Completion : WithDynamicRegistration
    {
        static class CompletionItem
        {
            import dls.protocol.definitions : MarkupKind;

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

        Nullable!CompletionItem completionItem;
        Nullable!CompletionItemKind completionItemKind;
        Nullable!bool contextSupport;
    }

    static class Hover : WithDynamicRegistration
    {
        import dls.protocol.definitions : MarkupKind;

        Nullable!(MarkupKind[]) contentFormat;
    }

    static class SignatureHelp : WithDynamicRegistration
    {
        static class SignatureInformation
        {
            import dls.protocol.definitions : MarkupKind;

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
        Nullable!bool hierarchicalDocumentSymbolSupport;
    }

    static class CodeAction : WithDynamicRegistration
    {
        static class CodeActionLiteralSupport
        {
            import dls.util.constructor : Constructor;

            static class CodeActionKind
            {
                import dls.protocol.interfaces.text_document : CodeActionKind;

                CodeActionKind[] valueSet;
            }

            CodeActionKind codeActionKind;

            mixin Constructor!CodeActionLiteralSupport;
        }

        Nullable!CodeActionLiteralSupport codeActionLiteralSupport;
    }

    static class Rename : WithDynamicRegistration
    {
        Nullable!bool prepareSupport;
    }

    static class PublishDiagnostics
    {
        Nullable!bool relatedInformation;
    }

    static class FoldingRange : WithDynamicRegistration
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
    Nullable!WithDynamicRegistration codeAction; // CodeAction poses some problems
    Nullable!WithDynamicRegistration codeLens;
    Nullable!WithDynamicRegistration documentLink;
    Nullable!WithDynamicRegistration colorProvider;
    Nullable!Rename rename;
    Nullable!PublishDiagnostics publishDiagnostics;
    Nullable!FoldingRange foldingRange;
}

class ClientCapabilities
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

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
    import std.typecons : Nullable;

    Nullable!bool resolveProvider;

    this(Nullable!bool resolveProvider = Nullable!bool.init)
    {
        this.resolveProvider = resolveProvider;
    }
}

class CompletionOptions : OptionsBase
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

class SignatureHelpOptions
{
    import std.typecons : Nullable;

    Nullable!(string[]) triggerCharacters;

    this(Nullable!(string[]) triggerCharacters = Nullable!(string[]).init)
    {
        this.triggerCharacters = triggerCharacters;
    }
}

class CodeActionOptions
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

class DocumentOnTypeFormattingOptions
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

class RenameOptions
{
    import std.typecons : Nullable;

    Nullable!bool prepareProvider;

    this(Nullable!bool prepareProvider = Nullable!bool.init)
    {
        this.prepareProvider = prepareProvider;
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
    import std.typecons : Nullable;

    Nullable!bool includeText;

    this(Nullable!bool includeText = Nullable!bool.init)
    {
        this.includeText = includeText;
    }
}

class ColorProviderOptions
{
}

class FoldingRangeProviderOptions
{
}

class TextDocumentSyncOptions
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

class StaticRegistrationOptions
{
    import std.typecons : Nullable;

    Nullable!string id;

    this(Nullable!string id = Nullable!string.init)
    {
        this.id = id;
    }
}

class ServerCapabilities
{
    import std.json : JSONValue;
    import std.typecons : Nullable;

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
    Nullable!bool typeDefinitionProvider;
    Nullable!JSONValue implementationProvider;
    Nullable!bool referencesProvider;
    Nullable!bool documentHighlightProvider;
    Nullable!bool documentSymbolProvider;
    Nullable!bool workspaceSymbolProvider;
    Nullable!JSONValue codeActionProvider;
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

class CancelParams
{
    import std.json : JSONValue;

    JSONValue id;
}
