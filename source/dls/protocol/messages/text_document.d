module dls.protocol.messages.text_document;

import logger = std.experimental.logger;
import dls.protocol.definitions;
import dls.protocol.interfaces.text_document;
import dls.server : Server;
import dls.tools.tools : Tools;
import dls.util.document : Document;
import dls.util.uri : Uri;
import std.typecons : Nullable;

void didOpen(DidOpenTextDocumentParams params)
{
    if (params.textDocument.languageId == "d")
    {
        auto uri = new Uri(params.textDocument.uri);
        logger.logf("Document opened: %s", uri.path);
        Document.open(params.textDocument);
        Server.send("textDocument/publishDiagnostics",
                new PublishDiagnosticsParams(uri, Tools.analysisTool.scan(uri)));
    }
}

void didChange(DidChangeTextDocumentParams params)
{
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Document changed: %s", uri.path);
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
    auto uri = new Uri(params.textDocument.uri);

    if (Document[uri])
    {
        logger.logf("Document saved: %s", uri.path);
        Server.send("textDocument/publishDiagnostics",
                new PublishDiagnosticsParams(uri, Tools.analysisTool.scan(uri)));
    }
}

void didClose(DidCloseTextDocumentParams params)
{
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Document closed: %s", uri.path);
    Document.close(params.textDocument);
    Server.send("textDocument/publishDiagnostics", new PublishDiagnosticsParams(uri, []));
}

CompletionItem[] completion(CompletionParams params)
{
    return Tools.symbolTool.complete(new Uri(params.textDocument.uri), params.position);
}

@("completionItem", "resolve")
CompletionItem completionItem_resolve(CompletionItem item)
{
    return Tools.symbolTool.completeResolve(item);
}

Hover hover(TextDocumentPositionParams params)
{
    return Tools.symbolTool.hover(new Uri(params.textDocument.uri), params.position);
}

SignatureHelp signatureHelp(TextDocumentPositionParams params)
{
    return null;
}

Location definition(TextDocumentPositionParams params)
{
    return Tools.symbolTool.find(new Uri(params.textDocument.uri), params.position);
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
    return Tools.symbolTool.highlight(new Uri(params.textDocument.uri), params.position);
}

SymbolInformation[] documentSymbol(DocumentSymbolParams params)
{
    return Tools.symbolTool.symbols("", new Uri(params.textDocument.uri));
}

Command[] codeAction(CodeActionParams params)
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
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Formatting %s", uri.path);
    return Tools.formatTool.format(uri, params.options);
}

TextEdit[] rangeFormatting(DocumentRangeFormattingParams params)
{
    return [];
}

TextEdit[] onTypeFormatting(DocumentOnTypeFormattingParams params)
{
    return [];
}

WorkspaceEdit[] rename(RenameParams params)
{
    return [];
}
