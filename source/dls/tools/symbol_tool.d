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
    import dls.util.document : Document;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ModuleCache;
    import dub.platform : BuildPlatform;
    import std.algorithm : map, sort, uniq;
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

    version (linux)
    {
        private static immutable snapPath = "/var/lib/snapd/snap";
    }

    private ModuleCache _cache;

    @property ref cache()
    {
        return _cache;
    }

    @property private auto defaultImportPaths()
    {
        import std.algorithm : each;
        import std.file : FileException, exists, readText;
        import std.range : replace;
        import std.regex : ctRegex, matchAll;

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
            if (paths.length == 0 && buildNormalizedPath(snapPath, "dmd").exists())
            {
                paths = ["druntime", "phobos"].map!(end => buildNormalizedPath(snapPath,
                        "dmd", "current", "import", end)).array;
            }
        }

        return paths.sort().uniq().array;
    }

    this()
    {
        import dsymbol.modulecache : ASTAllocator;

        _cache = ModuleCache(new ASTAllocator());
        _cache.addImportPaths(defaultImportPaths);
    }

    void importPath(Uri uri)
    {
        logger.logf("Importing from %s", uri.path);
        const d = getDub(uri);
        const desc = d.project.rootPackage.describe(BuildPlatform.any, null, null);
        importDirectories(desc.importPaths.map!(importPath => buildNormalizedPath(uri.path,
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
            importDirectories(desc.importPaths.map!(importPath => buildNormalizedPath(dep.path.toString(),
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
        import dls.protocol.interfaces : Location, TextDocumentItem;
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

    package void importDirectories(string[] paths)
    {
        import std.algorithm : canFind;

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
