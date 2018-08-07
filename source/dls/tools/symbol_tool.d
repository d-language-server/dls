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

module dls.tools.symbol_tool;

import dls.protocol.interfaces : CompletionItemKind, SymbolKind,
    SymbolInformation;
import dls.tools.tool : Tool;
import dparse.ast;
import dsymbol.symbol : CompletionKind;
import std.container : RedBlackTree;

int compareLocations(inout(SymbolInformation) s1, inout(SymbolInformation) s2)
{
    //dfmt off
    return s1.location.uri < s2.location.uri ? -1
        : s1.location.uri > s2.location.uri ? 1
        : s1.location.range.start.line < s2.location.range.start.line ? -1
        : s1.location.range.start.line > s2.location.range.start.line ? 1
        : s1.location.range.start.character < s2.location.range.start.character ? -1
        : s1.location.range.start.character > s2.location.range.start.character ? 1
        : 0;
    //dfmt on
}

alias SymbolInformationTree = RedBlackTree!(SymbolInformation, compareLocations, true);

private string[string] macros;
private CompletionItemKind[CompletionKind] completionKinds;
private SymbolKind[CompletionKind] symbolKinds;

shared static this()
{
    import dub.internal.vibecompat.core.log : LogLevel, setLogLevel;

    setLogLevel(LogLevel.none);
}

static this()
{
    //dfmt off
    macros = [
        "_"             : "",
        "B"             : "**$0**",
        "I"             : "_$0_",
        "U"             : "$0",
        "P"             : "\n\n$0",
        "DL"            : "$0",
        "DT"            : "$0",
        "DD"            : "$0",
        "TABLE"         : "$0",
        "TR"            : "$0",
        "TH"            : "$0",
        "TD"            : "$0",
        "OL"            : "\n\n$0",
        "UL"            : "\n\n$0",
        "LI"            : "- $0",
        "BIG"           : "$0",
        "SMALL"         : "$0",
        "BR"            : "\n\n$0",
        "LINK"          : "[$0]($0)",
        "LINK2"         : "[$1]($+)",
        "RED"           : "$0",
        "BLUE"          : "$0",
        "GREEN"         : "$0",
        "YELLOW"        : "$0",
        "BLACK"         : "$0",
        "WHITE"         : "$0",
        "D_CODE"        : "$0",
        "D_INLINE_CODE" : "$0",
        "LF"            : "\n",
        "LPAREN"        : "(",
        "RPAREN"        : ")",
        "BACKTICK"      : "`",
        "DOLLAR"        : "$",
        "DDOC"          : "$0",
        "BIGOH"         : "O($0)",
        "D"             : "$0",
        "D_COMMENT"     : "$0",
        "D_STRING"      : "\"$0\"",
        "D_KEYWORD"     : "$0",
        "D_PSYMBOL"     : "$0",
        "D_PARAM"       : "$0",
        "LREF"          : "$0",
        "REF"           : "$0",
        "REF1"          : "$0",
        "MREF"          : "$0",
        "MREF1"         : "$0"
    ];

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
}

void useCompatCompletionItemKinds(CompletionItemKind[] items = [])
{
    import std.algorithm : canFind;

    //dfmt off
    immutable map = [
        CompletionKind.structName  : CompletionItemKind.class_,
        CompletionKind.enumMember  : CompletionItemKind.field,
        CompletionKind.packageName : CompletionItemKind.module_
    ];
    //dfmt on

    foreach (ck, cik; map)
    {
        if (!items.canFind(completionKinds[ck]))
        {
            completionKinds[ck] = cik;
        }
    }
}

void useCompatSymbolKinds(SymbolKind[] symbols = [])
{
    import std.algorithm : canFind;

    //dfmt off
    immutable map = [
        CompletionKind.structName : SymbolKind.class_,
        CompletionKind.enumMember : SymbolKind.field
    ];
    //dfmt on

    foreach (ck, sk; map)
    {
        if (!symbols.canFind(symbolKinds[ck]))
        {
            symbolKinds[ck] = sk;
        }
    }
}

class SymbolTool : Tool
{
    import containers.hashset : HashSet;
    import dcd.common.messages : AutocompleteRequest, RequestKind;
    import dls.protocol.definitions : Location, MarkupContent, Position,
        WorkspaceEdit;
    import dls.protocol.interfaces : CompletionItem, DocumentHighlight, Hover;
    import dls.util.uri : Uri;
    import dsymbol.modulecache : ASTAllocator, ModuleCache;
    import dub.dub : Dub;

    version (Windows)
    {
        @property private static string[] _compilerConfigPaths()
        {
            import std.algorithm : splitter;
            import std.file : exists;
            import std.path : buildNormalizedPath;
            import std.process : environment;

            foreach (path; splitter(environment["PATH"], ';'))
            {
                if (exists(buildNormalizedPath(path, "dmd.exe")))
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
            "/Library/D/dmd/bin/dmd.conf", "/etc/dmd.conf", "/usr/local/etc/dmd.conf",
            "/usr/local/bin/dmd.conf", "/etc/ldc2.conf",
            "/usr/local/etc/ldc2.conf", "/home/linuxbrew/.linuxbrew/etc/dmd.conf"
        ];
    }
    else
    {
        private static immutable string[] _compilerConfigPaths;
    }

    private HashSet!string _workspaces;
    private ModuleCache _cache;

    @property ref ModuleCache cache()
    {
        return _cache;
    }

    @property private string[] defaultImportPaths()
    {
        import std.algorithm : each, filter, sort, splitter, uniq;
        import std.array : array, replace;
        import std.conv : to;
        import std.file : FileException, exists, readText;
        import std.path : asNormalizedPath, buildNormalizedPath, dirName;
        import std.process : environment;
        import std.regex : matchAll;

        string[] paths;

        foreach (confPath; _compilerConfigPaths)
        {
            if (exists(confPath))
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
            import std.algorithm : map;

            if (paths.length == 0)
            {
                foreach (path; ["/snap", "/var/lib/snapd/snap"])
                {
                    const dmdSnapPath = buildNormalizedPath(path, "dmd");
                    const ldcSnapIncludePath = buildNormalizedPath(path,
                            "ldc2", "current", "include", "d");

                    if (exists(dmdSnapPath))
                    {
                        paths = ["druntime", "phobos"].map!(end => buildNormalizedPath(dmdSnapPath,
                                "current", "import", end)).array;
                        break;
                    }
                    else if (exists(ldcSnapIncludePath))
                    {
                        paths = [ldcSnapIncludePath];
                        break;
                    }
                }
            }
        }

        version (Windows)
        {
            const pathSep = ';';
            const ldc = "ldc2.exe";
        }
        else
        {
            const pathSep = ':';
            const ldc = "ldc2";
        }

        if (paths.length == 0)
        {
            foreach (path; splitter(environment["PATH"], pathSep))
            {
                if (exists(buildNormalizedPath(path, ldc)))
                {
                    paths = [buildNormalizedPath(path, "..", "import")];
                }
            }
        }

        return paths.sort().uniq().filter!exists.array;
    }

    this()
    {
        _cache = ModuleCache(new ASTAllocator());
        importDirectories(defaultImportPaths);
    }

    void importPath(Uri uri)
    {
        import dub.platform : BuildPlatform;
        import std.algorithm : map;
        import std.array : array;
        import std.path : baseName, buildNormalizedPath;

        _workspaces.insert(uri.path);

        auto d = getDub(uri);
        auto packages = [d.project.rootPackage];

        foreach (sub; d.project.rootPackage.subPackages)
        {
            auto p = d.project.packageManager.getSubPackage(d.project.rootPackage,
                    baseName(sub.path), true);

            if (p !is null)
            {
                packages ~= p;
            }
        }

        foreach (p; packages)
        {
            const desc = p.describe(BuildPlatform.any, null, null);
            importDirectories(desc.importPaths.length > 0
                    ? desc.importPaths.map!(path => buildNormalizedPath(p.path.toString(),
                        path)).array : [uri.path]);
            importSelections(Uri.fromPath(desc.path));
        }
    }

    void importSelections(Uri uri)
    {
        import std.algorithm : map, reduce;
        import std.array : array;
        import std.path : buildNormalizedPath;

        const d = getDub(uri);

        foreach (dep; d.project.dependencies)
        {
            auto paths = reduce!(q{a ~ b})(cast(string[])[],
                    dep.recipe.buildSettings.sourcePaths.values);
            importDirectories(paths.map!(path => buildNormalizedPath(dep.path.toString(),
                    path)).array);
        }
    }

    void clearPath(Uri uri)
    {
        // import dls.util.logger : logger;

        // logger.infof("Clearing imports from %s", uri.path);
        // Implement ModuleCache.clear() in DCD
        _workspaces.remove(uri.path);
    }

    void upgradeSelections(Uri uri)
    {
        import dls.protocol.interfaces.dls : TranslationParams;
        import dls.protocol.messages.methods : Dls;
        import dls.util.constants : Tr;
        import dls.util.logger : logger;
        import std.concurrency : spawn;
        import std.path : dirName;

        logger.infof("Upgrading dependencies from %s", dirName(uri.path));

        spawn((string uriString) {
            import dls.protocol.jsonrpc : send;
            import dub.dub : UpgradeOptions;

            send(Dls.upgradeSelections_start,
                new TranslationParams(Tr.app_upgradeSelections_upgrading));
            getDub(new Uri(uriString)).upgrade(UpgradeOptions.upgrade | UpgradeOptions.select);
            send(Dls.upgradeSelections_stop);
        }, uri.toString());
    }

    SymbolInformation[] symbol(string query)
    {
        import dls.util.document : Document;
        import dls.util.logger : logger;
        import dsymbol.string_interning : internString;
        import dsymbol.symbol : DSymbol;
        import std.algorithm : any, canFind, map, startsWith;
        import std.array : appender, array;
        import std.file : SpanMode, dirEntries;
        import std.regex : matchFirst, regex;

        logger.infof(`Fetching symbols from workspace with query "%s"`, query);

        auto result = new SymbolInformationTree();

        static string commonName(string name)
        {
            switch (name)
            {
            case "*constructor*":
                return "this";

            default:
                return name;
            }
        }

        void collectSymbolInformations(Uri symbolUri, const(DSymbol)* symbol,
                string containerName = "")
        {
            import std.typecons : nullable;

            if (symbol.symbolFile != symbolUri.path)
            {
                return;
            }

            auto name = commonName(symbol.name);

            if (name.matchFirst(regex(query, "i")))
            {
                auto location = new Location(symbolUri,
                        Document[symbolUri].wordRangeAtByte(symbol.location));
                result.insert(new SymbolInformation(name,
                        symbolKinds[symbol.kind], location, containerName.nullable));
            }

            foreach (s; symbol.getPartsByName(internString(null)))
            {
                collectSymbolInformations(symbolUri, s, name);
            }
        }

        auto moduleUris = appender!(Uri[]);
        auto workspaces = _workspaces[];

        foreach (path; _cache.getImportPaths())
        {
            if (workspaces.any!(w => path.startsWith(w)))
            {
                foreach (entry; dirEntries(path, "*.{d,di}", SpanMode.breadth))
                {
                    moduleUris ~= Uri.fromPath(entry.name);
                }
            }
        }

        foreach (moduleUri; moduleUris.data)
        {
            if (Document.uris.map!q{a.path}.canFind(moduleUri.path))
            {
                result.insert(symbol(moduleUri, query));
                continue;
            }

            auto moduleSymbol = _cache.cacheModule(moduleUri.path);

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

        return result.array;
    }

    SymbolInformation[] symbol(Uri uri, string query)
    {
        import dls.util.document : Document;
        import dls.util.logger : logger;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import std.array : array;
        import std.functional : toDelegate;

        logger.infof(`Fetching symbols from %s`, uri.path);

        static void doNothing(string, size_t, size_t, string, bool)
        {
        }

        auto stringCache = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(Document[uri].toString(),
                LexerConfig(uri.path, StringBehavior.source), &stringCache);
        RollbackAllocator ra;
        const mod = parseModule(tokens, uri.path, &ra, toDelegate(&doNothing));
        auto result = new SymbolInformationTree();
        auto visitor = new SymbolVisitor(uri, query, result);
        visitor.visit(mod);

        return result.array;
    }

    CompletionItem[] completion(Uri uri, Position position)
    {
        import dcd.common.messages : AutocompleteResponse, CompletionType;
        import dcd.server.autocomplete : complete;
        import dls.util.logger : logger;
        import std.algorithm : chunkBy, map, sort, uniq;
        import std.array : array;
        import std.conv : to;
        import std.json : JSONValue;

        logger.infof("Fetching completions for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position, RequestKind.autocomplete);
        static bool compareCompletionsLess(AutocompleteResponse.Completion a,
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

        static bool compareCompletionsEqual(AutocompleteResponse.Completion a,
                AutocompleteResponse.Completion b)
        {
            return a.symbolFilePath == b.symbolFilePath && a.symbolLocation == b.symbolLocation;
        }

        auto result = complete(request, _cache);

        if (result.completionType != CompletionType.identifiers)
        {
            return [];
        }

        return result.completions
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

    CompletionItem completionResolve(CompletionItem item)
    {
        import std.algorithm : map;
        import std.array : array;

        if (!item.data.isNull)
        {
            item.documentation = getDocumentation(
                    item.data.array.map!q{ [a[0].str, a[1].str] }.array);
            item.data.nullify();
        }

        return item;
    }

    Hover hover(Uri uri, Position position)
    {
        import dcd.server.autocomplete : getDoc;
        import dls.util.logger : logger;
        import std.algorithm : filter, map, sort, uniq;
        import std.array : array;

        logger.infof("Fetching documentation for %s at position %s,%s",
                uri.path, position.line, position.character);

        auto request = getPreparedRequest(uri, position, RequestKind.doc);
        auto result = getDoc(request, _cache);
        auto completions = result.completions
            .map!q{a.documentation}
            .filter!q{a.length > 0}
            .array
            .sort().uniq();

        return completions.empty ? null
            : new Hover(getDocumentation(completions.map!q{ ["", a] }.array));
    }

    Location definition(Uri uri, Position position)
    {
        import dcd.server.autocomplete : findDeclaration;
        import dls.util.document : Document;
        import dls.util.logger : logger;

        logger.infof("Finding declaration for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position, RequestKind.symbolLocation);
        auto result = findDeclaration(request, _cache);
        if (result.symbolFilePath.length > 0)
        {
            auto resultUri = result.symbolFilePath == "stdin" ? uri
                : Uri.fromPath(result.symbolFilePath);
            openDocument(resultUri);
            return new Location(resultUri,
                    Document[resultUri].wordRangeAtByte(result.symbolLocation));
        }

        return null;
    }

    DocumentHighlight[] highlight(Uri uri, Position position)
    {
        import dcd.server.autocomplete.localuse : findLocalUse;
        import dls.protocol.interfaces : DocumentHighlightKind;
        import dls.util.document : Document;
        import dls.util.logger : logger;
        import std.algorithm : map;
        import std.array : array;
        import std.typecons : nullable;

        logger.infof("Highlighting usages for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position, RequestKind.localUse);
        auto result = findLocalUse(request, _cache);
        return result.completions.map!((res) => new DocumentHighlight(
                Document[uri].wordRangeAtByte(res.symbolLocation), (res.symbolLocation == result.symbolLocation
                ? DocumentHighlightKind.write : DocumentHighlightKind.text).nullable)).array;
    }

    WorkspaceEdit rename(Uri uri, Position position, string newName)
    {
        import dcd.server.autocomplete.localuse : findLocalUse;
        import dls.protocol.definitions : TextEdit;
        import dls.util.document : Document;
        import dls.util.logger : logger;
        import std.algorithm : map;
        import std.array : array;
        import std.typecons : nullable;

        logger.infof("Renaming symbol for %s at position %s,%s", uri.path,
                position.line, position.character);

        auto request = getPreparedRequest(uri, position, RequestKind.localUse);
        auto result = findLocalUse(request, _cache);

        if (result.symbolFilePath != "stdin")
        {
            return null;
        }

        auto changes = result.completions.map!(c => new TextEdit(
                Document[uri].wordRangeAtByte(c.symbolLocation), newName));
        return new WorkspaceEdit([uri.toString() : changes.array].nullable);
    }

    package void importDirectories(string[] paths)
    {
        import dls.util.logger : logger;

        logger.infof("Importing directories: %s", paths);
        _cache.addImportPaths(paths);
    }

    private MarkupContent getDocumentation(string[][] detailsAndDocumentations)
    {
        import ddoc : Lexer, expand;
        import dls.protocol.definitions : MarkupKind;
        import std.array : appender, replace;
        import std.regex : regex, split;

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
            auto content = documentation.split(regex(`\n-+(\n|$)`));
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
                    result ~= expand(Lexer(chunk.replace("\n", " ")), macros);
                    result ~= '\n';
                }

                isExample = !isExample;
            }
        }

        return new MarkupContent(MarkupKind.markdown, result.data);
    }

    private static AutocompleteRequest getPreparedRequest(Uri uri,
            Position position, RequestKind kind)
    {
        import dls.util.document : Document;

        auto request = AutocompleteRequest();
        auto document = Document[uri];

        request.fileName = uri.path;
        request.kind = kind;
        request.sourceCode = cast(ubyte[]) document.toString();
        request.cursorPosition = document.byteAtPosition(position);

        return request;
    }

    private static Dub getDub(Uri uri)
    {
        import std.file : isFile;
        import std.path : dirName;

        auto d = new Dub(isFile(uri.path) ? dirName(uri.path) : uri.path);
        d.loadPackage();
        return d;
    }

    private static bool openDocument(Uri docUri)
    {
        import dls.protocol.definitions : TextDocumentItem;
        import dls.util.document : Document;
        import std.file : readText;

        auto closed = Document[docUri] is null;

        if (closed)
        {
            auto doc = new TextDocumentItem();
            doc.uri = docUri;
            doc.languageId = "d";
            doc.text = readText(docUri.path);
            Document.open(doc);
        }

        return closed;
    }

    private static void closeDocument(Uri docUri, bool wasClosed)
    {
        import dls.util.document : Document;
        import dls.protocol.definitions : TextDocumentIdentifier;

        if (wasClosed)
        {
            auto docIdentifier = new TextDocumentIdentifier();
            docIdentifier.uri = docUri;
            Document.close(docIdentifier);
        }
    }
}

private class SymbolVisitor : ASTVisitor
{
    import dls.protocol.definitions : Location, Position;
    import dls.util.uri : Uri;
    import std.typecons : nullable;

    private Uri uri;
    private string query;
    private SymbolInformationTree result;
    private string containerName;

    this(Uri uri, string query, SymbolInformationTree result)
    {
        this.uri = uri;
        this.query = query;
        this.result = result;
    }

    override void visit(const ModuleDeclaration dec)
    {
        import std.algorithm : joiner, map;
        import std.array : array;
        import std.conv : to;

        containerName = dec.moduleName.identifiers.map!q{a.text}.array.dup.joiner(".").to!string;
        dec.accept(this);
    }

    override void visit(const ClassDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.class_, true);
    }

    override void visit(const StructDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.struct_, true);
    }

    override void visit(const InterfaceDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.interface_, true);
    }

    override void visit(const UnionDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.interface_, true);
    }

    override void visit(const EnumDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.enum_, true);
    }

    override void visit(const EnumMember mem)
    {
        visitSymbol(mem, SymbolKind.enumMember, false);
    }

    override void visit(const AnonymousEnumMember mem)
    {
        visitSymbol(mem, SymbolKind.enumMember, false);
    }

    override void visit(const TemplateDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.function_, true);
    }

    override void visit(const FunctionDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.function_, false);
    }

    override void visit(const Constructor dec)
    {
        tryInsert("this", SymbolKind.function_, getLocation(dec), containerName);
    }

    override void visit(const Destructor dec)
    {
        tryInsert("~this", SymbolKind.function_, getLocation(dec), containerName);
    }

    override void visit(const Invariant dec)
    {
        import dls.util.document : Document;

        tryInsert("invariant", SymbolKind.function_, new Location(uri,
                Document[uri].wordRangeAtLineAndByte(dec.line, dec.index)), containerName);
    }

    override void visit(const VariableDeclaration dec)
    {
        foreach (d; dec.declarators)
        {
            tryInsert(d.name.text, SymbolKind.variable, getLocation(d.name), containerName);
        }

        dec.accept(this);
    }

    override void visit(const AutoDeclaration dec)
    {
        foreach (part; dec.parts)
        {
            tryInsert(part.identifier.text, SymbolKind.variable,
                    getLocation(part.identifier), containerName);
        }

        dec.accept(this);
    }

    override void visit(const Unittest dec)
    {
    }

    override void visit(const AliasDeclaration dec)
    {
        if (dec.declaratorIdentifierList !is null)
        {
            foreach (id; dec.declaratorIdentifierList.identifiers)
            {
                tryInsert(id.text, SymbolKind.variable, getLocation(id), containerName);
            }
        }

        dec.accept(this);
    }

    override void visit(const AliasInitializer dec)
    {
        visitSymbol(dec, SymbolKind.variable, true);
    }

    override void visit(const AliasThisDeclaration dec)
    {
        tryInsert(dec.identifier.text, SymbolKind.variable,
                getLocation(dec.identifier), containerName);
        dec.accept(this);
    }

    private void visitSymbol(A)(const A dec, SymbolKind kind, bool accept)
            if (is(A : ASTNode))
    {
        tryInsert(dec.name.text.dup, kind, getLocation(dec.name), containerName);

        if (accept)
        {
            end(dec, dec.name.text.dup);
        }
    }

    private Location getLocation(T)(T t)
    {
        import dls.util.document : Document;

        return new Location(uri, Document[uri].wordRangeAtLineAndByte(t.line - 1, t.column - 1));
    }

    private void end(in ASTNode node, string name)
    {
        const oldName = containerName;
        containerName = name;
        node.accept(this);
        containerName = oldName;
    }

    private void tryInsert(string name, SymbolKind kind, Location location, string containerName)
    {
        import std.regex : matchFirst, regex;
        import std.typecons : nullable;

        if (query is null || name.matchFirst(regex(query, "i")))
        {
            result.insert(new SymbolInformation(name, kind, location, containerName.nullable));
        }
    }

    alias visit = ASTVisitor.visit;
}
