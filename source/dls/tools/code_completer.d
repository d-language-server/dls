module dls.tools.code_completer;

import common.messages;
import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.tools.tool;
import dls.util.document;
import dsymbol.modulecache;
import server.autocomplete;
import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.experimental.allocator;
import std.range;
import std.regex;

//dfmt off
private enum completionKinds = [
    'c' : CompletionItemKind.class_,
    'i' : CompletionItemKind.interface_,
    's' : CompletionItemKind.class_,
    'u' : CompletionItemKind.interface_,
    'v' : CompletionItemKind.variable,
    'm' : CompletionItemKind.field,
    'k' : CompletionItemKind.keyword,
    'f' : CompletionItemKind.method,
    'g' : CompletionItemKind.enum_,
    'e' : CompletionItemKind.field,
    'P' : CompletionItemKind.module_,
    'M' : CompletionItemKind.module_,
    'a' : CompletionItemKind.value,
    'A' : CompletionItemKind.value,
    'l' : CompletionItemKind.variable,
    't' : CompletionItemKind.function_,
    'T' : CompletionItemKind.function_
];
//dfmt on

class CodeCompleter : Tool!CodeCompleterConfiguration
{
    version (Posix)
    {
        private enum _dmdConfigPaths = [`/etc/dmd.conf`, `/usr/local/etc/dmd.conf`];
    }
    else version (Windows)
    {
        private enum _dmdConfigPaths = [`c:\D\dmd2\windows\bin\sc.ini`];
    }
    else
    {
        private enum string[] _dmdConfigPaths = [];
    }

    private static ModuleCache _cache = ModuleCache(new ASTAllocator());

    @property static void configuration(CodeCompleterConfiguration config)
    {
        Tool!CodeCompleterConfiguration.configuration(config);
        _cache.addImportPaths(_configuration.importPaths);
    }

    @property static auto importPaths()
    {
        string[] paths;

        foreach (confPath; _dmdConfigPaths)
        {
            if (exists(confPath))
            {
                try
                {
                    readText(confPath).matchAll(regex(`-I[^\s"]+`))
                        .each!((m) => paths ~= std.array.replace(m.hit[2 .. $], "%@P%", confPath));
                }
                catch (FileException e)
                {
                }
            }
        }

        return paths.sort().uniq().array;
    }

    static this()
    {
        _cache.addImportPaths(importPaths);
    }

    static auto complete(DocumentUri uri, Position position)
    {
        auto request = AutocompleteRequest();
        auto document = Document[uri];

        request.fileName = uri.findSplitAfter("://")[1];
        request.kind = RequestKind.autocomplete;
        request.sourceCode = cast(ubyte[]) document.toString();
        request.cursorPosition = document.bytePosition(position);

        auto result = server.autocomplete.complete(request, _cache);
        CompletionItem[] items;

        foreach (res; zip(result.completions, result.completionKinds))
        {
            items ~= new CompletionItem();

            with (items[$ - 1])
            {
                label = res[0];
                kind = completionKinds[res[1].to!char];
            }
        }

        return items.uniq!((a, b) => a.label == b.label).array;
    }
}

class CodeCompleterConfiguration : ToolConfiguration
{
    string[] importPaths;
}
