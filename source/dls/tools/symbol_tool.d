module dls.tools.symbol_tool;

import dls.protocol.interfaces : CompletionItemKind, SymbolKind;
import dls.tools.tool : Tool;
import dsymbol.symbol : CompletionKind;
import std.path : asNormalizedPath, buildNormalizedPath, dirName;

private immutable macroUrl = "https://raw.githubusercontent.com/dlang/dlang.org/stable/%s.ddoc";
private immutable macroFiles = ["html", "macros", "std", "std_consolidated", "std-ddox"];
private string[string] macros;
private immutable CompletionItemKind[CompletionKind] completionKinds;
private immutable SymbolKind[CompletionKind] symbolKinds;

@trusted shared static this()
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
    import dcd.common.messages : AutocompleteRequest, RequestKind;
    import dls.protocol.definitions : Location, MarkupContent, Position,
        TextDocumentItem;
    import dls.protocol.interfaces : CompletionItem, DocumentHighlight, Hover,
        SymbolInformation;
    import dls.util.document : Document;
    import dls.util.logger : logger;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ModuleCache;
    import dub.dub : Dub;
    import dub.platform : BuildPlatform;
    import std.algorithm : map, reduce, sort, uniq;
    import std.array : appender, array, replace;
    import std.container : RedBlackTree;
    import std.conv : to;
    import std.file : readText;
    import std.json : JSONValue;
    import std.net.curl : byLine;
    import std.parallelism : Task;
    import std.range : chain;
    import std.regex : matchFirst;
    import std.typecons : nullable;

    version (Windows)
    {
        @safe @property private static string[] _compilerConfigPaths()
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

    private Task!(byLine, string)*[] _macroTasks;
    private ModuleCache*[string] _workspaceCaches;
    private ModuleCache*[string] _libraryCaches;

    @safe @property private string[] defaultImportPaths()
    {
        import std.algorithm : each;
        import std.file : FileException, exists;
        import std.regex : matchAll;

        string[] paths;

        foreach (confPath; _compilerConfigPaths)
        {
            if (confPath.exists())
            {
                try
                {
                    readText(confPath).matchAll(`-I[^\s"]+`)
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

    @safe this()
    {
        import std.format : format;
        import std.parallelism : task;

        foreach (macroFile; macroFiles)
        {
            auto t = task!byLine(format!macroUrl(macroFile));
            _macroTasks ~= t;
            t.executeInNewThread();
        }

        importDirectories!true("", defaultImportPaths);
    }

    @safe ModuleCache*[] getRelevantCaches(Uri uri)
    {
        auto result = appender([getWorkspaceCache(uri)]);

        foreach (path; _libraryCaches.byKey)
        {
            if (path.length > 0)
            {
                result ~= _libraryCaches[path];
            }
        }

        result ~= _libraryCaches[""];

        return result.data;
    }

    @safe ModuleCache* getWorkspaceCache(Uri uri)
    {
        import std.algorithm : startsWith;
        import std.path : pathSplitter;

        string[] cachePathParts;

        foreach (path; chain(_workspaceCaches.byKey, _libraryCaches.byKey))
        {
            auto splitter = pathSplitter(path);

            if (pathSplitter(uri.path).startsWith(splitter))
            {
                auto pathParts = splitter.array;

                if (pathParts.length > cachePathParts.length)
                {
                    cachePathParts = pathParts;
                }
            }
        }

        auto cachePath = buildNormalizedPath(cachePathParts);
        return cachePath in _workspaceCaches ? _workspaceCaches[cachePath]
            : _libraryCaches[cachePath];
    }

    @trusted void importPath(Uri uri)
    {
        const d = getDub(uri);
        const desc = d.project.rootPackage.describe(BuildPlatform.any, null, null);
        importDirectories!false(uri.path,
                desc.importPaths.map!(importPath => buildNormalizedPath(uri.path,
                    importPath)).array);
    }

    @trusted void importSelections(Uri uri)
    {
        const d = getDub(uri);
        const project = d.project;

        foreach (dep; project.dependencies)
        {
            const desc = dep.describe(BuildPlatform.any, null,
                    dep.name in project.rootPackage.recipe.buildSettings.subConfigurations
                    ? project.rootPackage.recipe.buildSettings.subConfigurations[dep.name] : null);
            importDirectories!true(dep.name,
                    desc.importPaths.map!(importPath => buildNormalizedPath(dep.path.toString(),
                        importPath)).array, true);
        }
    }

    @safe void clearPath(Uri uri)
    {
        logger.logf("Clearing imports from %s", uri.path);

        if (uri.path in _workspaceCaches)
        {
            _workspaceCaches.remove(uri.path);
        }
        else
        {
            _libraryCaches.remove(uri.path);
        }
    }

    @trusted void upgradeSelections(Uri uri)
    {
        import std.concurrency : spawn;

        logger.logf("Upgrading dependencies from %s", dirName(uri.path));

        spawn((string uriString) {
            import dub.dub : UpgradeOptions;

            getDub(new Uri(uriString)).upgrade(UpgradeOptions.upgrade | UpgradeOptions.select);
        }, uri.toString());
    }

    @trusted SymbolInformation[] symbol(string query, Uri uri = null)
    {
        import dsymbol.string_interning : internString;
        import dsymbol.symbol : DSymbol;

        logger.logf(`Fetching symbols from %s with query "%s"`, uri is null
                ? "workspace" : uri.path, query);

        auto result = new RedBlackTree!(SymbolInformation, q{a.name > b.name}, true);

        @trusted void collectSymbolInformations(Uri symbolUri,
                const(DSymbol)* symbol, string containerName = "")
        {
            if (symbol.symbolFile != symbolUri.path)
            {
                return;
            }

            if (symbol.name.data.matchFirst(query))
            {
                auto location = new Location(symbolUri,
                        Document[symbolUri].wordRangeAtByte(symbol.location));
                result.insert(new SymbolInformation(symbol.name,
                        symbolKinds[symbol.kind], location, containerName.nullable));
            }

            foreach (s; symbol.getPartsByName(internString(null)))
            {
                collectSymbolInformations(symbolUri, s, symbol.name);
            }
        }

        @trusted static Uri[] getModuleUris(ModuleCache* cache)
        {
            import std.file : SpanMode, dirEntries;

            auto result = appender!(Uri[]);

            foreach (rootPath; cache.getImportPaths())
            {
                foreach (entry; dirEntries(rootPath, "*.{d,di}", SpanMode.breadth))
                {
                    result ~= Uri.fromPath(entry.name);
                }
            }

            return result.data;
        }

        foreach (cache; _workspaceCaches.byValue)
        {
            auto moduleUris = uri is null ? getModuleUris(cache) : [uri];

            foreach (moduleUri; moduleUris)
            {
                auto moduleSymbol = cache.cacheModule(moduleUri.path);

                if (moduleSymbol !is null)
                {
                    const closed = openDocument(moduleUri);

                    foreach (symbol; moduleSymbol.getPartsByName(internString(null)))
                    {
                        collectSymbolInformations(moduleUri, symbol);
                    }

                    closeDocument(moduleUri, closed);
                }
            }
        }

        return result.array;
    }

    @trusted CompletionItem[] completion(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteResponse;
        import dcd.server.autocomplete : complete;
        import std.algorithm : chunkBy;

        logger.logf("Getting completions for %s at position %s,%s",
                uri.path, position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.autocomplete;

        @safe static bool compareCompletionsLess(AutocompleteResponse.Completion a,
                AutocompleteResponse.Completion b)
        {
            //dfmt off
            return a.identifier < b.identifier ? true
                : a.identifier > b.identifier ? false
                : a.symbolFilePath < b.symbolFilePath ? true
                : a.symbolFilePath > b.symbolFilePath ? false
                : a.symbolLocation < b.symbolLocation;
            //dfmt on
        }

        @safe static bool compareCompletionsEqual(AutocompleteResponse.Completion a,
                AutocompleteResponse.Completion b)
        {
            return a.symbolFilePath == b.symbolFilePath && a.symbolLocation == b.symbolLocation;
        }

        return chain(_workspaceCaches.byValue, _libraryCaches.byValue).map!(
                cache => complete(request, *cache).completions)
            .reduce!q{a ~ b}
            .sort!compareCompletionsLess
            .uniq!compareCompletionsEqual
            .chunkBy!q{a.identifier == b.identifier}
            .map!((resultGroup) {
                import std.uni : toLower;

                auto firstResult = resultGroup.front;
                auto item = new CompletionItem(firstResult.identifier);
                item.kind = completionKinds[firstResult.kind.to!CompletionKind];
                item.detail = firstResult.definition;

                string[][] data;

                foreach (res; resultGroup)
                {
                    if (res.documentation.length > 0 && res.documentation.toLower() != "ditto")
                    {
                        data ~= [res.definition, res.documentation];
                    }
                }

                if (data.length > 0)
                {
                    item.data = JSONValue(data);
                }

                return item;
            })
            .array;
    }

    @trusted CompletionItem completionResolve(CompletionItem item)
    {
        if (!item.data.isNull)
        {
            item.documentation = getDocumentation(
                    item.data.array.map!q{ [a[0].str, a[1].str] }.array);
            item.data.nullify();
        }

        return item;
    }

    @trusted Hover hover(Uri uri, Position position)
    {
        import dcd.server.autocomplete : getDoc;
        import std.algorithm : filter;

        logger.logf("Getting documentation for %s at position %s,%s",
                uri.path, position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.doc;
        auto completions = getRelevantCaches(uri).map!(cache => getDoc(request,
                *cache).completions)
            .reduce!q{a ~ b}
            .map!q{a.documentation}
            .filter!q{a.length > 0}
            .array
            .sort().uniq();

        return completions.empty ? null
            : new Hover(getDocumentation(completions.map!q{ ["", a] }.array));
    }

    @trusted Location definition(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteResponse;
        import dcd.server.autocomplete : findDeclaration;
        import std.algorithm : find;

        logger.logf("Finding declaration for %s at position %s,%s",
                uri.path, position.line, position.character);

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

        auto resultUri = results[0].symbolFilePath == "stdin" ? uri
            : Uri.fromPath(results[0].symbolFilePath);
        openDocument(resultUri);

        return new Location(resultUri,
                Document[resultUri].wordRangeAtByte(results[0].symbolLocation));
    }

    @trusted DocumentHighlight[] highlight(Uri uri, Position position)
    {
        import dcd.server.autocomplete.localuse : findLocalUse;
        import dls.protocol.interfaces : DocumentHighlightKind;

        logger.logf("Highlighting usages for %s at position %s,%s",
                uri.path, position.line, position.character);

        static bool highlightLess(in DocumentHighlight a, in DocumentHighlight b)
        {
            return a.range.start.line < b.range.start.line
                || (a.range.start.line == b.range.start.line
                        && a.range.start.character < b.range.start.character);
        }

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.localUse;
        auto result = new RedBlackTree!(DocumentHighlight, highlightLess, false);

        foreach (cache; getRelevantCaches(uri))
        {
            auto localUse = findLocalUse(request, *cache);
            result.insert(localUse.completions.map!((res) => new DocumentHighlight(
                    Document[uri].wordRangeAtByte(res.symbolLocation), (res.symbolLocation == localUse.symbolLocation
                    ? DocumentHighlightKind.write : DocumentHighlightKind.text).nullable)));
        }

        return result.array;
    }

    @trusted package void importDirectories(bool isLibrary)(string root,
            string[] paths, bool refresh = false)
    {
        import dsymbol.modulecache : ASTAllocator;
        import std.algorithm : canFind;

        logger.logf(`Importing into cache "%s": %s`, root, paths);

        static if (isLibrary)
        {
            alias caches = _libraryCaches;
        }
        else
        {
            alias caches = _workspaceCaches;
        }

        if (refresh && (root in caches))
        {
            caches.remove(root);
        }

        if (!(root in caches))
        {
            caches[root] = new ModuleCache(new ASTAllocator());
        }

        foreach (path; paths)
        {
            if (!caches[root].getImportPaths().canFind(path))
            {
                caches[root].addImportPaths([path]);
            }
        }
    }

    @trusted private MarkupContent getDocumentation(string[][] detailsAndDocumentations)
    {
        import arsd.htmltotext : htmlToText;
        import ddoc : Lexer, expand;
        import dls.protocol.definitions : MarkupKind;
        import std.algorithm : all;
        import std.net.curl : CurlException;
        import std.regex : regex, split;

        try
        {
            if (macros.keys.length == 0 && _macroTasks.all!q{a.done})
            {
                foreach (macroTask; _macroTasks)
                {
                    foreach (line; macroTask.yieldForce())
                    {
                        auto result = matchFirst(line, `(\w+)\s*=\s*(.*)`);

                        if (result.length > 0)
                        {
                            macros[result[1].to!string] = result[2].to!string;
                        }
                    }
                }
            }
        }
        catch (CurlException e)
        {
            logger.error("Could not fetch macros");
            macros["_"] = "";
        }

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
            auto content = documentation.split(regex(`\n-+(\n|$)`))
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
                    auto html = expand(Lexer(chunk), macros).replace(`<i>`, ``)
                        .replace(`</i>`, ``).replace(`*`, `\*`).replace(`_`, `\_`);
                    result ~= htmlToText(html);
                    result ~= '\n';
                }

                isExample = !isExample;
            }
        }

        return new MarkupContent(MarkupKind.markdown, result.data);
    }

    @trusted private static AutocompleteRequest getPreparedRequest(Uri uri, Position position)
    {
        auto request = AutocompleteRequest();
        auto document = Document[uri];

        request.fileName = uri.path;
        request.sourceCode = cast(ubyte[]) document.toString();
        request.cursorPosition = document.byteAtPosition(position);

        return request;
    }

    @trusted private static Dub getDub(Uri uri)
    {
        import std.file : isFile;

        auto d = new Dub(isFile(uri.path) ? dirName(uri.path) : uri.path);
        d.loadPackage();
        return d;
    }

    @trusted private static bool openDocument(Uri docUri)
    {
        import std.array : replaceFirst;
        import std.encoding : getBOM;

        auto closed = Document[docUri] is null;

        if (closed)
        {
            auto doc = new TextDocumentItem();
            doc.uri = docUri;
            doc.languageId = "d";
            auto text = readText(docUri.path);
            doc.text = text.replaceFirst(cast(string) getBOM(cast(ubyte[]) text).sequence, "");
            Document.open(doc);
        }

        return closed;
    }

    @safe private static void closeDocument(Uri docUri, bool wasClosed)
    {
        import dls.protocol.definitions : TextDocumentIdentifier;

        if (wasClosed)
        {
            auto docIdentifier = new TextDocumentIdentifier();
            docIdentifier.uri = docUri;
            Document.close(docIdentifier);
        }
    }
}
