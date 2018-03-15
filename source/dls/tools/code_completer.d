module dls.tools.code_completer;

import dcd.common.messages;
import dcd.server.autocomplete;
import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.tools.tool;
import dls.util.document;
import dls.util.uri;
import dsymbol.modulecache;
import dub.dub;
import dub.internal.vibecompat.core.log;
import dub.platform;
import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.experimental.allocator;
import std.path;
import std.range;
import std.regex;
import std.stdio;

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

static this()
{
    setLogLevel(LogLevel.none);
}

class CodeCompleter : Tool!CodeCompleterConfiguration
{
    version (Posix)
    {
        private static immutable _dmdConfigPaths = [`/etc/dmd.conf`, `/usr/local/etc/dmd.conf`];
    }
    else version (Windows)
    {
        private static immutable _dmdConfigPaths = [`c:\D\dmd2\windows\bin\sc.ini`];
    }
    else
    {
        private static immutable string[] _dmdConfigPaths;
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
                        .each!((m) => paths ~= m.hit[2 .. $].replace("%@P%", confPath.dirName).asNormalizedPath().to!string);
                }
                catch (FileException e)
                {
                    // File doesn't exist or could't be read
                }
            }
        }

        return paths.sort().uniq().array;
    }

    static this()
    {
        _cache.addImportPaths(importPaths);
    }

    static void importSelections(Uri uri)
    {
        auto d = new Dub(dirName(uri.path));

        d.loadPackage();
        d.upgrade(UpgradeOptions.select);

        auto project = d.project;

        foreach (dep; project.dependencies)
        {
            auto desc = dep.describe(BuildPlatform.any, null,
                    dep.name in project.rootPackage.recipe.buildSettings.subConfigurations
                    ? project.rootPackage.recipe.buildSettings.subConfigurations[dep.name] : null);

            _cache.addImportPaths(desc.importPaths.map!((importPath) => buildPath(dep.path.toString(),
                    importPath)).array);
        }
    }

    static auto complete(Uri uri, Position position)
    {
        auto request = AutocompleteRequest();
        auto document = Document[uri];

        request.fileName = uri.path;
        request.kind = RequestKind.autocomplete;
        request.sourceCode = cast(ubyte[]) document.toString();
        request.cursorPosition = document.bytePosition(position);

        auto result = dcd.server.autocomplete.complete.complete(request, _cache);
        CompletionItem[] items;

        foreach (res; result.completions)
        {
            items ~= new CompletionItem();

            with (items[$ - 1])
            {
                label = res.identifier;
                kind = completionKinds[res.kind.to!char];
            }
        }

        return items.uniq!((a, b) => a.label == b.label).array;
    }
}

class CodeCompleterConfiguration : ToolConfiguration
{
    string[] importPaths;
}
