module dls.protocol.messages.text_document;

import logger = std.experimental.logger;
import dls.protocol.interfaces;
import dls.tools.tools : Tools;
import dls.util.document : Document;
import dls.util.uri : Uri;

void didOpen(DidOpenTextDocumentParams params)
{
    if (params.textDocument.languageId == "d")
    {
        logger.logf("Document opened: %s", new Uri(params.textDocument.uri).path);
        Document.open(params.textDocument);
    }
}

void didChange(DidChangeTextDocumentParams params)
{
    logger.logf("Document changed: %s", new Uri(params.textDocument.uri).path);
    Document.change(params.textDocument, params.contentChanges);
}

void willSave(WillSaveTextDocumentParams params)
{
}

auto willSaveWaitUntil(WillSaveTextDocumentParams params)
{
    TextEdit[] result;
    return result;
}

void didSave(DidSaveTextDocumentParams params)
{
}

void didClose(DidCloseTextDocumentParams params)
{
    logger.logf("Document closed: %s", new Uri(params.textDocument.uri).path);
    Document.close(params.textDocument);
}

auto completion(CompletionParams params)
{
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Getting completions for %s at position %s,%s", uri.path,
            params.position.line, params.position.character);
    return Tools.symbolTool.complete(uri, params.position);
}

@("completionItem", "resolve")
auto completionItem_resolve(CompletionItem item)
{
    return item;
}

auto hover(TextDocumentPositionParams params)
{
    auto result = new Hover();
    return result;
}

auto signatureHelp(TextDocumentPositionParams params)
{
    auto result = new SignatureHelp();
    return result;
}

auto definition(TextDocumentPositionParams params)
{
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Finding declaration for %s at position %s,%s", uri.path,
            params.position.line, params.position.character);
    return Tools.symbolTool.find(uri, params.position);
}

auto typeDefinition(TextDocumentPositionParams params)
{
    auto result = new Location();
    return result.nullable;
}

auto implementation(TextDocumentPositionParams params)
{
    auto result = new Location();
    return result.nullable;
}

auto references(ReferenceParams params)
{
    Location[] result;
    return result;
}

auto documentHighlight(TextDocumentPositionParams params)
{
    DocumentHighlight[] result;
    return result;
}

auto documentSymbol(DocumentSymbolParams params)
{
    SymbolInformation[] result;
    return result;
}

auto codeAction(CodeActionParams params)
{
    Command[] result;
    return result;
}

auto codeLens(CodeLensParams params)
{
    CodeLens[] result;
    return result;
}

@("codeLens", "resolve")
auto codeLens_resolve(CodeLens codeLens)
{
    return codeLens;
}

auto documentLink(DocumentLinkParams params)
{
    DocumentLink[] result;
    return result;
}

@("documentLink", "resolve")
auto documentLink_resolve(DocumentLink link)
{
    return link;
}

auto documentColor(DocumentColorParams params)
{
    ColorInformation[] result;
    return result;
}

auto colorPresentation(ColorPresentationParams params)
{
    ColorPresentation[] result;
    return result;
}

auto formatting(DocumentFormattingParams params)
{
    auto uri = new Uri(params.textDocument.uri);
    logger.logf("Formatting %s", uri.path);
    return Tools.formatTool.format(uri, params.options);
}

auto rangeFormatting(DocumentRangeFormattingParams params)
{
    TextEdit[] result;
    return result;
}

auto onTypeFormatting(DocumentOnTypeFormattingParams params)
{
    TextEdit[] result;
    return result;
}

auto rename(RenameParams params)
{
    WorkspaceEdit[] result;
    return result;
}
