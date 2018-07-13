module dls.protocol.messages.methods;

//dfmt off
final class General
{
    @disable this() {}

    static immutable initialize    = "initialize";
    static immutable initialized   = "initialized";
    static immutable shutdown      = "shutdown";
    static immutable exit          = "exit";
    static immutable cancelRequest = "$/cancelRequest";
}

final class Window
{
    @disable this() {}

    static immutable showMessage           = "window/showMessage";
    static immutable showMessageRequest    = "window/showMessageRequest";
    static immutable logMessage            = "window/logMessage";
}

final class Telemetry
{
    @disable this() {}

    static immutable event = "telemetry/event";
}

final class Client
{
    @disable this() {}

    static immutable registerCapability    = "client/registerCapability";
    static immutable unregisterCapability  = "client/unregisterCapability";
}

final class Workspace
{
    @disable this() {}

    static immutable workspaceFolders          = "workspace/workspaceFolders";
    static immutable didChangeWorkspaceFolders = "workspace/didChangeWorkspaceFolders";
    static immutable configuration             = "workspace/configuration";
    static immutable didChangeWatchedFiles     = "workspace/didChangeWatchedFiles";
    static immutable symbol                    = "workspace/symbol";
    static immutable executeCommand            = "workspace/executeCommand";
    static immutable applyEdit                 = "workspace/applyEdit";
}

final class TextDocument
{
    @disable this() {}

    static immutable didOpen               = "textDocument/didOpen";
    static immutable didChange             = "textDocument/didChange";
    static immutable willSave              = "textDocument/willSave";
    static immutable willSaveWaitUntil     = "textDocument/willSaveWaitUntil";
    static immutable didSave               = "textDocument/didSave";
    static immutable didClose              = "textDocument/didClose";
    static immutable publishDiagnostics    = "textDocument/publishDiagnostics";
    static immutable completion            = "textDocument/completion";
    static immutable completionResolve     = "completionItem/resolve";
    static immutable hover                 = "textDocument/hover";
    static immutable signatureHelp         = "textDocument/signatureHelp";
    static immutable definition            = "textDocument/definition";
    static immutable typeDefinition        = "textDocument/typeDefinition";
    static immutable implementation        = "textDocument/implementation";
    static immutable references            = "textDocument/references";
    static immutable documentHighlight     = "textDocument/documentHighlight";
    static immutable documentSymbol        = "textDocument/documentSymbol";
    static immutable codeAction            = "textDocument/codeAction";
    static immutable codeLens              = "textDocument/codeLens";
    static immutable codeLensResolve       = "codeLens/resolve";
    static immutable documentLink          = "textDocument/documentLink";
    static immutable documentLinkResolve   = "documentLink/resolve";
    static immutable documentColor         = "textDocument/documentColor";
    static immutable colorPresentation     = "textDocument/colorPresentation";
    static immutable formatting            = "textDocument/formatting";
    static immutable rangeFormatting       = "textDocument/rangeFormatting";
    static immutable onTypeFormatting      = "textDocument/onTypeFormatting";
    static immutable rename                = "textDocument/rename";
}

final class Dls
{
    @disable this() {}

    static immutable upgradeDls_start          = "$/dls.upgradeDls.start";
    static immutable upgradeDls_stop           = "$/dls.upgradeDls.stop";
    static immutable upgradeDls_totalSize      = "$/dls.upgradeDls.totalSize";
    static immutable upgradeDls_currentSize    = "$/dls.upgradeDls.currentSize";
    static immutable upgradeDls_extract        = "$/dls.upgradeDls.extract";
    static immutable upgradeSelections_start   = "$/dls.upgradeSelections.start";
    static immutable upgradeSelections_stop    = "$/dls.upgradeSelections.stop";
}
//dfmt on
