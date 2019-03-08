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
import std.json : JSONValue;
import std.typecons : Nullable;

void didOpen(DidOpenTextDocumentParams params)
{
    import dls.protocol.logger : logger;
    import dls.util.document : Document;
    import dls.util.uri : Uri;

    auto uri = new Uri(params.textDocument.uri);
    logger.info("Document opened: %s", uri.path);

    if (!Document.open(params.textDocument))
    {
        logger.warning("Document %s is already open", uri.path);
    }
}

void didChange(DidChangeTextDocumentParams params)
{
    import dls.protocol.logger : logger;
    import dls.util.document : Document;
    import dls.util.uri : Uri;

    auto uri = new Uri(params.textDocument.uri);
    logger.info("Document changed: %s", uri.path);

    if (!Document.change(params.textDocument, params.contentChanges))
    {
        logger.warning("Document %s is not open", uri.path);
    }
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
    import dls.protocol.logger : logger;
    import dls.util.uri : Uri;

    auto uri = new Uri(params.textDocument.uri);
    logger.info("Document saved: %s", uri.path);
}

void didClose(DidCloseTextDocumentParams params)
{
    import dls.protocol.logger : logger;
    import dls.util.document : Document;
    import dls.util.uri : Uri;

    auto uri = new Uri(params.textDocument.uri);
    logger.info("Document closed: %s", uri.path);

    if (!Document.close(params.textDocument))
    {
        logger.warning("Document %s is not open", uri.path);
    }
}

CompletionItem[] completion(CompletionParams params)
{
    return [];
}

@("completionItem", "resolve")
CompletionItem completionItem_resolve(CompletionItem item)
{
    return null;
}

Hover hover(TextDocumentPositionParams params)
{
    return null;
}

SignatureHelp signatureHelp(TextDocumentPositionParams params)
{
    return null;
}

Location[] declaration(TextDocumentPositionParams params)
{
    return [];
}

Location[] definition(TextDocumentPositionParams params)
{
    return [];
}

Location[] typeDefinition(TextDocumentPositionParams params)
{
    return [];
}

Location implementation(TextDocumentPositionParams params)
{
    return null;
}

Location[] references(ReferenceParams params)
{
    return [];
}

DocumentHighlight[] documentHighlight(TextDocumentPositionParams params)
{
    return [];
}

JSONValue documentSymbol(DocumentSymbolParams params) // (DocumentSymbol | SymbolInformation)[]
{
    return JSONValue();
}

JSONValue codeAction(CodeActionParams params) // (Command | CodeAction)[]
{
    return JSONValue();
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
    return [];
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
    return null;
}

Range prepareRename(TextDocumentPositionParams params)
{
    return null;
}

FoldingRange[] foldingRange(FoldingRangeParams params)
{
    return [];
}
