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

module dls.protocol.messages.text_document;

import dls.protocol.definitions;
import dls.protocol.interfaces.text_document;
import dls.util.uri : Uri;
import std.typecons : Nullable;

void didOpen(DidOpenTextDocumentParams params)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : TextDocument;
    import dls.tools.tools : Tools;
    import dls.util.document : Document;
    import dls.util.logger : logger;

    if (params.textDocument.languageId == "d")
    {
        auto uri = new Uri(params.textDocument.uri);
        logger.infof("Document opened: %s", uri.path);
        Document.open(params.textDocument);
        send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri,
                Tools.analysisTool.scan(uri)));
    }
}

void didChange(DidChangeTextDocumentParams params)
{
    import dls.util.document : Document;
    import dls.util.logger : logger;

    auto uri = new Uri(params.textDocument.uri);
    logger.infof("Document changed: %s", uri.path);
    Document.change(params.textDocument, params.contentChanges);
}

void willSave(WillSaveTextDocumentParams params)
{
}

TextEdit[] willSaveWaitUntil(WillSaveTextDocumentParams params)
{
    return [];
}

void didSave(DidSaveTextDocumentParams params)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : TextDocument;
    import dls.tools.tools : Tools;
    import dls.util.document : Document;
    import dls.util.logger : logger;

    auto uri = new Uri(params.textDocument.uri);

    if (Document[uri])
    {
        logger.infof("Document saved: %s", uri.path);
        send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri,
                Tools.analysisTool.scan(uri)));
    }
}

void didClose(DidCloseTextDocumentParams params)
{
    import dls.protocol.jsonrpc : send;
    import dls.protocol.messages.methods : TextDocument;
    import dls.util.document : Document;
    import dls.util.logger : logger;

    auto uri = new Uri(params.textDocument.uri);
    logger.infof("Document closed: %s", uri.path);
    Document.close(params.textDocument);
    send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri, []));
}

CompletionItem[] completion(CompletionParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.completion(new Uri(params.textDocument.uri), params.position);
}

@("completionItem", "resolve")
CompletionItem completionItem_resolve(CompletionItem item)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.completionResolve(item);
}

Hover hover(TextDocumentPositionParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.hover(new Uri(params.textDocument.uri), params.position);
}

SignatureHelp signatureHelp(TextDocumentPositionParams params)
{
    return null;
}

Location definition(TextDocumentPositionParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.definition(new Uri(params.textDocument.uri), params.position);
}

Nullable!Location typeDefinition(TextDocumentPositionParams params)
{
    return Nullable!Location();
}

Nullable!Location implementation(TextDocumentPositionParams params)
{
    return Nullable!Location();
}

Location[] references(ReferenceParams params)
{
    return [];
}

DocumentHighlight[] documentHighlight(TextDocumentPositionParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.highlight(new Uri(params.textDocument.uri), params.position);
}

SymbolInformation[] documentSymbol(DocumentSymbolParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.symbol(new Uri(params.textDocument.uri), null);
}

CodeAction[] codeAction(CodeActionParams params)
{
    return [];
}

CodeLens[] codeLens(CodeLensParams params)
{
    return [];
}

@("codeLens", "resolve")
CodeLens codeLens_resolve(CodeLens codeLens)
{
    return codeLens;
}

DocumentLink[] documentLink(DocumentLinkParams params)
{
    return [];
}

@("documentLink", "resolve")
DocumentLink documentLink_resolve(DocumentLink link)
{
    return link;
}

ColorInformation[] documentColor(DocumentColorParams params)
{
    return [];
}

ColorPresentation[] colorPresentation(ColorPresentationParams params)
{
    return [];
}

TextEdit[] formatting(DocumentFormattingParams params)
{
    import dls.tools.tools : Tools;

    auto uri = new Uri(params.textDocument.uri);
    return Tools.formatTool.formatting(uri, params.options);
}

TextEdit[] rangeFormatting(DocumentRangeFormattingParams params)
{
    return [];
}

TextEdit[] onTypeFormatting(DocumentOnTypeFormattingParams params)
{
    return [];
}

WorkspaceEdit rename(RenameParams params)
{
    import dls.tools.tools : Tools;

    return Tools.symbolTool.rename(new Uri(params.textDocument.uri),
            params.position, params.newName);
}

FoldingRange[] foldingRanges(FoldingRangeRequestParams params)
{
    return [];
}
