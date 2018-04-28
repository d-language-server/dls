module dls.tools.symbol_tool;

import dls.protocol.interfaces : CompletionItemKind;
import dls.tools.tool : Tool;
import std.path : asNormalizedPath, buildNormalizedPath, dirName;

private immutable CompletionItemKind[char] completionKinds;

static this()
{
    import dub.internal.vibecompat.core.log : LogLevel, setLogLevel;

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

class SymbolTool : Tool
{
    import logger = std.experimental.logger;
    import dcd.common.messages : RequestKind;
    import dls.protocol.definitions : Position;
    import dls.protocol.interfaces : CompletionItem;
    import dls.util.document : Document;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ASTAllocator, ModuleCache;
    import dub.platform : BuildPlatform;
    import std.algorithm : map, sort, uniq;
    import std.array : appender, array;
    import std.conv : to;
    import std.regex : ctRegex;

    version (Windows)
    {
        @property private static string[] _compilerConfigPaths()
        {
            import std.algorithm : splitter;
            import std.file : exists;
            import std.process : environment;

            foreach (path; splitter(environment["PATH"], ';'))
            {
                if (buildNormalizedPath(path, "dmd.exe").exists())
                {
                    return [buildNormalizedPath(path, "sc.ini")];
                }
            }

            return [];
        }
    }
    else version (Posix)
    {
        private static immutable _compilerConfigPaths = [
            `/etc/dmd.conf`, `/usr/local/etc/dmd.conf`, `/etc/ldc2.conf`,
            `/usr/local/etc/ldc2.conf`
        ];
    }
    else
    {
        private static immutable string[] _compilerConfigPaths;
    }

    private ModuleCache*[string] _caches;

    @property private auto defaultImportPaths()
    {
        import std.algorithm : each;
        import std.file : FileException, exists, readText;
        import std.range : replace;
        import std.regex : matchAll;

        string[] paths;

        foreach (confPath; _compilerConfigPaths)
        {
            if (confPath.exists())
            {
                try
                {
                    readText(confPath).matchAll(ctRegex!`-I[^\s"]+`)
                        .each!(m => paths ~= m.hit[2 .. $].replace("%@P%",
                                confPath.dirName).asNormalizedPath().to!string);
                    break;
                }
                catch (FileException e)
                {
                    // File doesn't exist or could't be read
                }
            }
        }

        version (linux)
        {
            if (paths.length == 0)
            {
                foreach (path; ["/snap", "/var/lib/snapd/snap"])
                {
                    if (buildNormalizedPath(path, "dmd").exists())
                    {
                        paths = ["druntime", "phobos"].map!(end => buildNormalizedPath(path,
                                "dmd", "current", "import", end)).array;
                        break;
                    }
                }
            }
        }

        return paths.sort().uniq().array;
    }

    this()
    {
        _caches[""] = new ModuleCache(new ASTAllocator());
        _caches[""].addImportPaths(defaultImportPaths);
    }

    auto getRelevantCaches(Uri uri)
    {
        import std.path : isAbsolute;

        auto result = appender([getWorkspaceCache(uri)]);

        foreach (pair; _caches.byKeyValue)
        {
            if (!pair.key.isAbsolute)
            {
                result ~= pair.value;
            }
        }

        result ~= _caches[""];

        return result.data;
    }

    auto getWorkspaceCache(Uri uri)
    {
        import std.algorithm : startsWith;
        import std.array : array;
        import std.path : pathSplitter;

        string[] cachePathParts;

        foreach (path; _caches.byKey)
        {
            if (pathSplitter(uri.path).startsWith(pathSplitter(path)))
            {
                auto pathParts = pathSplitter(path).array;

                if (pathParts.length > cachePathParts.length)
                {
                    cachePathParts = pathParts;
                }
            }
        }

        return _caches[buildNormalizedPath(cachePathParts)];
    }

    void importPath(Uri uri)
    {
        logger.logf("Importing from %s", uri.path);
        const d = getDub(uri);
        const desc = d.project.rootPackage.describe(BuildPlatform.any, null, null);
        importDirectories(uri.path,
                desc.importPaths.map!(importPath => buildNormalizedPath(uri.path,
                    importPath)).array);
    }

    void importSelections(Uri uri)
    {
        logger.logf("Importing dependencies from %s", uri.path);
        const d = getDub(uri);
        const project = d.project;

        foreach (dep; project.dependencies)
        {
            const desc = dep.describe(BuildPlatform.any, null,
                    dep.name in project.rootPackage.recipe.buildSettings.subConfigurations
                    ? project.rootPackage.recipe.buildSettings.subConfigurations[dep.name] : null);
            importDirectories(dep.name, desc.importPaths.map!(importPath => buildNormalizedPath(dep.path.toString(),
                    importPath)).array, true);
        }
    }

    void clearPath(Uri uri)
    {
        logger.logf("Clearing imports from %s", uri.path);
        _caches.remove(uri.path);
    }

    void upgradeSelections(Uri uri)
    {
        import std.concurrency : spawn;

        logger.logf("Upgrading dependencies from %s", dirName(uri.path));

        spawn((string uriString) {
            import dub.dub : UpgradeOptions;

            getDub(new Uri(uriString)).upgrade(UpgradeOptions.select);
        }, uri.toString());
    }

    auto complete(Uri uri, Position position)
    {
        import dcd.server.autocomplete : complete;
        import std.algorithm : reduce;
        import std.json : JSONValue;

        logger.logf("Getting completions for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.autocomplete;

        return _caches.byValue.map!(cache => complete(request, *cache).completions)
            .reduce!"a ~ b".sort!q{a.identifier > b.identifier}.uniq!q{a.identifier == b.identifier}.map!(
                    (res) {
                auto item = new CompletionItem(res.identifier);
                item.kind = completionKinds[res.kind.to!char];
                item.detail = res.definition;
                item.data = JSONValue(res.documentation);
                return item;
            }).array;
    }

    auto completeResolve(CompletionItem item)
    {
        if (!item.data.isNull)
        {
            item.documentation = getDocumentation(item.data.str);
        }

        return item;
    }

    auto find(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteResponse;
        import dcd.server.autocomplete : findDeclaration;
        import dls.protocol.definitions : Location, TextDocumentItem;
        import std.algorithm : find;
        import std.file : readText;

        logger.logf("Finding declaration for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.symbolLocation;

        AutocompleteResponse[] results;

        foreach (cache; getRelevantCaches(uri))
        {
            results ~= findDeclaration(request, *cache);
        }

        results = results.find!"a.symbolFilePath.length > 0".array;

        if (results.length == 0)
        {
            return null;
        }

        auto resultPath = results[0].symbolFilePath == "stdin" ? uri.path
            : results[0].symbolFilePath;
        const externalDocument = Document[resultPath] is null;

        if (externalDocument)
        {
            auto doc = new TextDocumentItem();
            doc.uri = resultPath;
            doc.languageId = "d";
            doc.text = readText(resultPath);
            Document.open(doc);
        }

        auto resultUri = Uri.fromPath(resultPath);
        return new Location(resultUri,
                Document[resultPath].wordRangeAtByte(results[0].symbolLocation));
    }

    auto highlight(Uri uri, Position position)
    {
        import dcd.server.autocomplete.localuse : findLocalUse;
        import dls.protocol.interfaces : DocumentHighlight,
            DocumentHighlightKind;
        import std.typecons : nullable;

        logger.logf("Highlighting usages for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.localUse;
        auto result = findLocalUse(request, *getWorkspaceCache(uri));

        return result.completions.map!((res) => new DocumentHighlight(
                Document[uri].wordRangeAtByte(res.symbolLocation), (res.symbolLocation == result.symbolLocation
                ? DocumentHighlightKind.write : DocumentHighlightKind.text).nullable)).array;
    }

    package void importDirectories(string root, string[] paths, bool refresh = false)
    {
        import std.algorithm : canFind;

        if (refresh && (root in _caches))
        {
            _caches.remove(root);
        }

        if (!(root in _caches))
        {
            _caches[root] = new ModuleCache(new ASTAllocator());
        }

        foreach (path; paths)
        {
            if (!_caches[root].getImportPaths().canFind(path))
            {
                _caches[root].addImportPaths([path]);
            }
        }
    }

    private static auto getPreparedRequest(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteRequest;

        auto request = AutocompleteRequest();
        auto document = Document[uri];

        request.fileName = uri.path;
        request.sourceCode = cast(ubyte[]) document.toString();
        request.cursorPosition = document.byteAtPosition(position);

        return request;
    }

    private static auto getDub(Uri uri)
    {
        import dub.dub : Dub;
        import std.file : isFile;

        auto d = new Dub(isFile(uri.path) ? dirName(uri.path) : uri.path);
        d.loadPackage();
        return d;
    }

    private static auto getDocumentation(string documentation)
    {
        import dls.protocol.definitions : MarkupContent, MarkupKind;

        import std.array : replace;
        import std.regex : split;

        auto content = documentation.split(ctRegex!`\n-+(\n|$)`)
            .map!(chunk => chunk.replace(`\n`, " "));
        auto result = appender!string;
        bool isExample;

        foreach (chunk; content)
        {
            if (isExample)
            {
                result ~= "```d\n";
                result ~= chunk;
                result ~= "\n```\n";
            }
            else
            {
                result ~= chunk;
                result ~= '\n';
            }

            isExample = !isExample;
        }

        return new MarkupContent(MarkupKind.markdown, result.data);
    }
}
