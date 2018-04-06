module dls.tools.symbol_tool;

import dls.protocol.interfaces : CompletionItemKind;
import dls.tools.tool : Tool;
import std.algorithm;
import std.path;

private enum diagnosticSource = "D-Scanner";
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
    import dls.tools.configuration : Configuration;
    import dls.util.document : Document;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ASTAllocator, ModuleCache;
    import dub.platform : BuildPlatform;
    import std.array : array;
    import std.conv : to;

    version (Posix)
    {
        private static immutable _compilerConfigPaths = [
            `/etc/dmd.conf`, `/usr/local/etc/dmd.conf`, `/etc/ldc2.conf`,
            `/usr/local/etc/ldc2.conf`
        ];
    }
    else version (Windows)
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
    else
    {
        private static immutable string[] _compilerConfigPaths;
    }

    private ModuleCache _cache = ModuleCache(new ASTAllocator());

    @property override void configuration(Configuration config)
    {
        super.configuration(config);
        _cache.addImportPaths(_configuration.symbol.importPaths);
    }

    @property private auto defaultImportPaths()
    {
        import std.file : FileException, exists, readText;
        import std.range : replace;
        import std.regex : ctRegex, matchAll;

        string[] paths;

        foreach (confPath; _compilerConfigPaths)
        {
            if (exists(confPath))
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

        return paths.sort().uniq().array;
    }

    this()
    {
        _cache.addImportPaths(defaultImportPaths);
    }

    void importPath(Uri uri)
    {
        logger.logf("Importing from %s", uri.path);
        const d = getDub(uri);
        const desc = d.project.rootPackage.describe(BuildPlatform.any, null, null);
        importDirectories(desc.importPaths.map!(importPath => buildPath(uri.path,
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
            importDirectories(desc.importPaths.map!(importPath => buildPath(dep.path.toString(),
                    importPath)).array);
        }
    }

    void upgradeSelections(Uri uri)
    {
        import std.concurrency : spawn;

        logger.logf("Upgrading dependencies from %s", dirName(uri.path));

        spawn((string uriString) {
            import dub.dub : UpgradeOptions;

            auto d = getDub(new Uri(uriString));
            d.upgrade(UpgradeOptions.select);
        }, uri.toString());
    }

    auto complete(Uri uri, Position position)
    {
        import dcd.server.autocomplete : complete;
        import dls.protocol.interfaces : CompletionItem;

        logger.logf("Getting completions for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.autocomplete;

        auto result = complete(request, _cache);
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

    auto find(Uri uri, Position position)
    {
        import dcd.server.autocomplete : findDeclaration;
        import dls.protocol.interfaces : Location, Range, TextDocumentItem;
        import std.file : readText;

        logger.logf("Finding declaration for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position);
        request.kind = RequestKind.symbolLocation;

        auto result = findDeclaration(request, _cache);

        if (result.symbolFilePath.length == 0)
        {
            return null;
        }

        auto resultPath = result.symbolFilePath == "stdin" ? uri.path : result.symbolFilePath;
        const externalDocument = Document[resultPath] is null;

        if (externalDocument)
        {
            auto doc = new TextDocumentItem();
            doc.uri = resultPath;
            doc.languageId = "d";
            doc.text = readText(resultPath);
            Document.open(doc);
        }

        auto location = new Location();
        location.uri = Uri.fromPath(resultPath);
        location.range = Document[resultPath].wordRangeAtByte(result.symbolLocation);
        return location.uri.length ? location : null;
    }

    auto scan(Uri uri)
    {
        import dls.protocol.definitions : Diagnostic, DiagnosticSeverity;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import dscanner.analysis.config : defaultStaticAnalysisConfig;
        import dscanner.analysis.run : analyze;
        import std.json : JSONValue;

        logger.logf("Scanning document %s", uri.path);

        LexerConfig lexerConfig;
        lexerConfig.fileName = uri.path;
        lexerConfig.stringBehavior = StringBehavior.source;

        auto stringCache = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(Document[uri].toString(), lexerConfig, &stringCache);
        RollbackAllocator ra;
        auto document = Document[uri];
        Diagnostic[] diagnostics;

        const syntaxProblemhandler = delegate(string path, size_t line,
                size_t column, string msg, bool isError) {
            auto d = new Diagnostic();
            d.range = document.wordRangeAtLineAndByte(line - 1, column - 1);
            d.severity = isError ? DiagnosticSeverity.error : DiagnosticSeverity.warning;
            d.source = diagnosticSource;
            d.message = msg;
            diagnostics ~= d;
        };

        const mod = parseModule(tokens, uri.path, &ra, syntaxProblemhandler);
        const analysisConfig = defaultStaticAnalysisConfig();
        const analysisResults = analyze(uri.path, mod, analysisConfig, _cache, tokens, true);

        foreach (result; analysisResults)
        {
            auto d = new Diagnostic();
            d.range = document.wordRangeAtLineAndByte(result.line - 1, result.column - 1);
            d.severity = DiagnosticSeverity.warning;
            d.code = JSONValue(result.key);
            d.source = diagnosticSource;
            d.message = result.message;
            diagnostics ~= d;
        }

        return diagnostics;
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

    private auto getPreparedRequest(Uri uri, Position position)
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
}
