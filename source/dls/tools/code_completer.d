module dls.tools.code_completer;

import dcd.common.messages;
import dcd.server.autocomplete;
import dls.protocol.definitions;
import dls.protocol.interfaces;
import dls.tools.configuration;
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

private immutable CompletionItemKind[char] completionKinds;

static this()
{
    //dfmt off
    completionKinds = [
        'c' : CompletionItemKind.class_,
        'i' : CompletionItemKind.interface_,
        's' : CompletionItemKind.struct_,
        'u' : CompletionItemKind.interface_,
        'v' : CompletionItemKind.variable,
        'm' : CompletionItemKind.field,
        'k' : CompletionItemKind.keyword,
        'f' : CompletionItemKind.method,
        'g' : CompletionItemKind.enum_,
        'e' : CompletionItemKind.enumMember,
        'P' : CompletionItemKind.folder,
        'M' : CompletionItemKind.module_,
        'a' : CompletionItemKind.value,
        'A' : CompletionItemKind.value,
        'l' : CompletionItemKind.variable,
        't' : CompletionItemKind.function_,
        'T' : CompletionItemKind.function_
    ];
    //dfmt on

    setLogLevel(LogLevel.none);
}

class CodeCompleter : Tool
{
    version (Posix)
    {
        private static immutable _compilerConfigPaths = [
            `/etc/dmd.conf`, `/usr/local/etc/dmd.conf`, `/etc/ldc2.conf`,
            `/usr/local/etc/ldc2.conf`
        ];
    }
    else version (Windows)
    {
        private static immutable _compilerConfigPaths = [`c:\D\dmd2\windows\bin\sc.ini`];
    }
    else
    {
        private static immutable string[] _compilerConfigPaths;
    }

    private ModuleCache _cache = ModuleCache(new ASTAllocator());

    @property override void configuration(Configuration config)
    {
        super.configuration(config);
        _cache.addImportPaths(_configuration.general.importPaths);
    }

    @property auto importPaths()
    {
        string[] paths;

        foreach (confPath; _compilerConfigPaths)
        {
            if (exists(confPath))
            {
                try
                {
                    readText(confPath).matchAll(regex(`-I[^\s"]+`))
                        .each!((m) => paths ~= m.hit[2 .. $].replace("%@P%",
                                confPath.dirName).asNormalizedPath().to!string);
                    break;
                }
                catch (FileException e)
                {
                    // File doesn't exist or could't be read
                }
            }
        }

        return paths.sort().uniq().array;
    }

    this()
    {
        _cache.addImportPaths(importPaths);
    }

    void importPath(Uri uri)
    {
        auto d = new Dub(isFile(uri.path) ? dirName(uri.path) : uri.path);
        d.loadPackage();
        importDirectories(d.project.rootPackage.describe(BuildPlatform.any, null, null).importPaths);
    }

    void importSelections(Uri uri)
    {
        auto d = new Dub(isFile(uri.path) ? dirName(uri.path) : uri.path);
        d.loadPackage();
        d.upgrade(UpgradeOptions.select);

        const project = d.project;

        foreach (dep; project.dependencies)
        {
            const desc = dep.describe(BuildPlatform.any, null,
                    dep.name in project.rootPackage.recipe.buildSettings.subConfigurations
                    ? project.rootPackage.recipe.buildSettings.subConfigurations[dep.name] : null);

            auto newImportPaths = desc.importPaths.map!(
                    (importPath) => buildPath(dep.path.toString(), importPath));

            importDirectories(newImportPaths.array);
        }
    }

    private void importDirectories(string[] paths)
    {
        foreach (path; paths)
        {
            if (!_cache.getImportPaths().canFind(path))
            {
                _cache.addImportPaths([path]);
            }
        }
    }

    auto complete(Uri uri, Position position)
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

        return items.sort!((a, b) => a.label < b.label).uniq!((a, b) => a.label == b.label).array;
    }
}
