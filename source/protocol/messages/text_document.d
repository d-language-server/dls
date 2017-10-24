module protocol.messages.text_document;

import protocol.handlers;
import protocol.interfaces.text_document;
import util.json;

void didOpen(Nullable!JSONValue jsonParams)
{
}

void didChange(Nullable!JSONValue jsonParams)
{
}

void willSave(Nullable!JSONValue jsonParams)
{
}

ResponseData willSaveWaitUntil(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

void didSave(Nullable!JSONValue jsonParams)
{
}

ResponseData didClose(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData completion(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

@("completionItem", "resolve")
ResponseData completionItem_resolve(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData hover(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData signatureHelp(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData references(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData documentHighlight(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData documentSymbol(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData formatting(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData rangeFormatting(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData onTypeFormatting(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData definition(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData codeAction(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData codeLens(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

@("codeLens", "resolve")
ResponseData codeLens_resolve(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData documentLink(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

@("documentLink", "resolve")
ResponseData documentLink_resolve(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}

ResponseData rename(Nullable!JSONValue jsonParams)
{
    return ResponseData();
}
