module dls.tools.symbol_tool;

import dls.protocol.interfaces : CompletionItemKind, SymbolKind;
import dls.tools.tool : Tool;
import dsymbol.symbol : CompletionKind;
import std.path : asNormalizedPath, buildNormalizedPath, dirName;

private immutable CompletionItemKind[CompletionKind] completionKinds;
private immutable SymbolKind[CompletionKind] symbolKinds;

static this()
{
    import dub.internal.vibecompat.core.log : LogLevel, setLogLevel;

    //dfmt off
    completionKinds = [
        CompletionKind.className            : CompletionItemKind.class_,
        CompletionKind.interfaceName        : CompletionItemKind.interface_,
        CompletionKind.structName           : CompletionItemKind.struct_,
        CompletionKind.unionName            : CompletionItemKind.interface_,
        CompletionKind.variableName         : CompletionItemKind.variable,
        CompletionKind.memberVariableName   : CompletionItemKind.field,
        CompletionKind.keyword              : CompletionItemKind.keyword,
        CompletionKind.functionName         : CompletionItemKind.function_,
        CompletionKind.enumName             : CompletionItemKind.enum_,
        CompletionKind.enumMember           : CompletionItemKind.enumMember,
        CompletionKind.packageName          : CompletionItemKind.folder,
        CompletionKind.moduleName           : CompletionItemKind.module_,
        CompletionKind.aliasName            : CompletionItemKind.variable,
        CompletionKind.templateName         : CompletionItemKind.function_,
        CompletionKind.mixinTemplateName    : CompletionItemKind.function_
    ];

    symbolKinds = [
        CompletionKind.className            : SymbolKind.class_,
        CompletionKind.interfaceName        : SymbolKind.interface_,
        CompletionKind.structName           : SymbolKind.struct_,
        CompletionKind.unionName            : SymbolKind.interface_,
        CompletionKind.variableName         : SymbolKind.variable,
        CompletionKind.memberVariableName   : SymbolKind.field,
        CompletionKind.keyword              : SymbolKind.constant,
        CompletionKind.functionName         : SymbolKind.function_,
        CompletionKind.enumName             : SymbolKind.enum_,
        CompletionKind.enumMember           : SymbolKind.enumMember,
        CompletionKind.packageName          : SymbolKind.package_,
        CompletionKind.moduleName           : SymbolKind.module_,
        CompletionKind.aliasName            : SymbolKind.variable,
        CompletionKind.templateName         : SymbolKind.function_,
        CompletionKind.mixinTemplateName    : SymbolKind.function_
    ];
    //dfmt on

    setLogLevel(LogLevel.none);
}

class SymbolTool : Tool
{
    import logger = std.experimental.logger;
    import dcd.common.messages : RequestKind;
    import dls.protocol.definitions : Location, Position, TextDocumentItem;
    import dls.protocol.interfaces : CompletionItem;
    import dls.util.document : Document;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ASTAllocator, ModuleCache;
    import dub.platform : BuildPlatform;
    import std.algorithm : map, reduce, sort, uniq;
    import std.array : appender, array;
    import std.conv : to;
    import std.file : readText;
    import std.json : JSONValue;
    import std.path : isAbsolute;
    import std.regex : ctRegex;
    import std.typecons : nullable;

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
        import std.file : FileException, exists;
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
        auto result = appender([getWorkspaceCache(uri)]);

        foreach (pair; _caches.byKeyValue)
        {
            if (pair.key.length > 0 && !pair.key.isAbsolute)
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

    auto symbols(string query)
    {
        import dls.protocol.definitions : TextDocumentIdentifier;
        import dls.protocol.interfaces : SymbolInformation;
        import dsymbol.string_interning : internString;
        import dsymbol.symbol : DSymbol;
        import std.regex : regex;

        logger.log("Fetching workspaces symbols");

        const queryRegex = regex(query);
        auto result = appender!(SymbolInformation[]);

        SymbolInformation[] getSymbolInformations(Uri uri,
                const(DSymbol)* symbol, string containerName = "")
        {
            import std.regex : matchFirst;
            import std.stdio : stderr;

            if (symbol.symbolFile.length == 0)
            {
                return [];
            }

            auto location = new Location(uri, Document[uri].wordRangeAtByte(symbol.location));
            auto result = appender!(SymbolInformation[]);

            if (symbol.name.data.matchFirst(queryRegex))
            {
                result ~= new SymbolInformation(symbol.name,
                        symbolKinds[symbol.kind], location, containerName.nullable);
            }

            foreach (s; symbol.getPartsByName(internString("")))
            {
                result ~= getSymbolInformations(uri, s, symbol.name);
            }

            return result.data;
        }

        foreach (pair; _caches.byKeyValue)
        {
            if (pair.key.length > 0 && pair.key.isAbsolute)
            {
                foreach (cacheEntry; pair.value.getAllSymbols())
                {
                    auto uri = Uri.fromPath(cacheEntry.symbol.symbolFile);
                    const closedDoc = Document[uri] is null;

                    if (closedDoc)
                    {
                        auto doc = new TextDocumentItem();
                        doc.uri = uri;
                        doc.languageId = "d";
                        doc.text = readText(uri.path);
                        Document.open(doc);
                    }

                    foreach (symbol; cacheEntry.symbol.getPartsByName(internString("")))
                    {
                        result ~= getSymbolInformations(uri, symbol);
                    }

                    if (closedDoc)
                    {
                        auto docIdentifier = new TextDocumentIdentifier();
                        docIdentifier.uri = uri;
                        Document.close(docIdentifier);
                    }
                }
            }
        }

        return result.data;
    }

    auto complete(Uri uri, Position position)
    {
        import dcd.server.autocomplete : complete;
        import std.algorithm : chunkBy;

        logger.logf("Getting completions for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.autocomplete;

        return _caches.byValue.map!(cache => complete(request, *cache).completions)
            .reduce!q{a ~ b}.chunkBy!q{a.identifier == b.identifier}.map!((resGroup) {
                auto item = new CompletionItem(resGroup.front.identifier);
                item.kind = completionKinds[resGroup.front.kind.to!CompletionKind];
                item.detail = resGroup.front.definition;

                string[][] data;

                foreach (res; resGroup)
                {
                    data ~= [res.definition, res.documentation];
                }

                item.data = JSONValue(data);
                return item;
            }).array;
    }

    auto completeResolve(CompletionItem item)
    {
        if (!item.data.isNull)
        {
            item.documentation = getDocumentation(
                    item.data.array.map!q{ [a[0].str, a[1].str] }.array);
            item.data.nullify();
        }

        return item;
    }

    auto hover(Uri uri, Position position)
    {
        import dcd.server.autocomplete : getDoc;
        import dls.protocol.interfaces : Hover;
        import std.algorithm : filter;

        logger.logf("Getting documentation for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.doc;

        auto completions = getRelevantCaches(uri).map!(cache => getDoc(request, *cache).completions)
            .reduce!q{a ~ b}.map!q{a.documentation}.filter!q{a.length > 0}.array.sort().uniq();

        return completions.empty ? null
            : new Hover(getDocumentation(completions.map!q{ ["", a] }.array));
    }

    auto find(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteResponse;
        import dcd.server.autocomplete : findDeclaration;
        import std.algorithm : find;

        logger.logf("Finding declaration for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.symbolLocation;

        AutocompleteResponse[] results;

        foreach (cache; getRelevantCaches(uri))
        {
            results ~= findDeclaration(request, *cache);
        }

        results = results.find!q{a.symbolFilePath.length > 0}.array;

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

    private static auto getDocumentation(string[][] detailsAndDocumentations)
    {
        import dls.protocol.definitions : MarkupContent, MarkupKind;

        import std.array : replace;
        import std.regex : split;

        auto result = appender!string;
        bool putSeparator;

        foreach (dad; detailsAndDocumentations)
        {
            if (putSeparator)
            {
                result ~= "\n\n---\n\n";
            }
            else
            {
                putSeparator = true;
            }

            auto detail = dad[0];
            auto documentation = dad[1];
            auto content = documentation.split(ctRegex!`\n-+(\n|$)`)
                .map!(chunk => chunk.replace(`\n`, " "));
            bool isExample;

            if (detail.length > 0 && detailsAndDocumentations.length > 1)
            {
                result ~= "### ";
                result ~= detail;
                result ~= "\n\n";
            }

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
        }

        return new MarkupContent(MarkupKind.markdown, result.data);
    }
}
