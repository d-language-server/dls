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

module dls.protocol.messages.methods;

//dfmt off
enum General : string
{
    initialize    = "initialize",
    initialized   = "initialized",
    shutdown      = "shutdown",
    exit          = "exit",
    cancelRequest = "$/cancelRequest",
}

enum Window : string
{
    showMessage           = "window/showMessage",
    showMessageRequest    = "window/showMessageRequest",
    logMessage            = "window/logMessage",
}

enum Telemetry : string
{
    event = "telemetry/event",
}

enum Client : string
{
    registerCapability    = "client/registerCapability",
    unregisterCapability  = "client/unregisterCapability",
}

enum Workspace : string
{
    workspaceFolders          = "workspace/workspaceFolders",
    didChangeWorkspaceFolders = "workspace/didChangeWorkspaceFolders",
    configuration             = "workspace/configuration",
    didChangeWatchedFiles     = "workspace/didChangeWatchedFiles",
    symbol                    = "workspace/symbol",
    executeCommand            = "workspace/executeCommand",
    applyEdit                 = "workspace/applyEdit",
}

enum TextDocument : string
{
    didOpen               = "textDocument/didOpen",
    didChange             = "textDocument/didChange",
    willSave              = "textDocument/willSave",
    willSaveWaitUntil     = "textDocument/willSaveWaitUntil",
    didSave               = "textDocument/didSave",
    didClose              = "textDocument/didClose",
    publishDiagnostics    = "textDocument/publishDiagnostics",
    completion            = "textDocument/completion",
    completionResolve     = "completionItem/resolve",
    hover                 = "textDocument/hover",
    signatureHelp         = "textDocument/signatureHelp",
    declaration           = "textDocument/declaration",
    definition            = "textDocument/definition",
    typeDefinition        = "textDocument/typeDefinition",
    implementation        = "textDocument/implementation",
    references            = "textDocument/references",
    documentHighlight     = "textDocument/documentHighlight",
    documentSymbol        = "textDocument/documentSymbol",
    codeAction            = "textDocument/codeAction",
    codeLens              = "textDocument/codeLens",
    codeLensResolve       = "codeLens/resolve",
    documentLink          = "textDocument/documentLink",
    documentLinkResolve   = "documentLink/resolve",
    documentColor         = "textDocument/documentColor",
    colorPresentation     = "textDocument/colorPresentation",
    formatting            = "textDocument/formatting",
    rangeFormatting       = "textDocument/rangeFormatting",
    onTypeFormatting      = "textDocument/onTypeFormatting",
    rename                = "textDocument/rename",
    prepareRename         = "textDocument/prepareRename",
    foldingRange          = "textDocument/foldingRange",
}

interface Dls
{
    enum UpgradeDls : string
    {
        didStart                = "$/dls/upgradeDls/didStart",
        didStop                 = "$/dls/upgradeDls/didStop",
        didChangeTotalSize      = "$/dls/upgradeDls/didChangeTotalSize",
        didChangeCurrentSize    = "$/dls/upgradeDls/didChangeCurrentSize",
        didExtract              = "$/dls/upgradeDls/didExtract",
    }

    enum UpgradeSelections : string
    {
        didStart    = "$/dls/upgradeSelections/didStart",
        didStop     = "$/dls/upgradeSelections/didStop",
    }
}
//dfmt on
