module dls.protocol.messages.text_document;

import dls.protocol.definitions;
import dls.protocol.interfaces.text_document;
import dls.protocol.jsonrpc : send;
import dls.protocol.messages.methods : TextDocument;
import dls.tools.tools : Tools;
import dls.util.document : Document;
import dls.util.logger : logger;
import dls.util.uri : Uri;
import std.typecons : Nullable;

void didOpen(DidOpenTextDocumentParams params)
{
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
    auto uri = new Uri(params.textDocument.uri);
    logger.infof("Document closed: %s", uri.path);
    Document.close(params.textDocument);
    send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri, []));
}

CompletionItem[] completion(CompletionParams params)
{
    return Tools.symbolTool.completion(new Uri(params.textDocument.uri), params.position);
}

@("completionItem", "resolve")
CompletionItem completionItem_resolve(CompletionItem item)
{
    return Tools.symbolTool.completionResolve(item);
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
    return Tools.symbolTool.highlight(new Uri(params.textDocument.uri), params.position);
}

SymbolInformation[] documentSymbol(DocumentSymbolParams params)
{
    return Tools.symbolTool.symbol("", new Uri(params.textDocument.uri));
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
    auto uri = new Uri(params.textDocument.uri);
    logger.infof("Formatting %s", uri.path);
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

WorkspaceEdit[] rename(RenameParams params)
{
    return [];
}
