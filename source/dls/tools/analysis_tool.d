module dls.tools.analysis_tool;

import dls.tools.tool : Tool;

private immutable diagnosticSource = "D-Scanner";

class AnalysisTool : Tool
{
    import dls.protocol.definitions : Diagnostic;
    import dls.util.uri : Uri;
    import dscanner.analysis.config : StaticAnalysisConfig,
        defaultStaticAnalysisConfig;
    import std.experimental.logger : logf;
    import std.path : buildNormalizedPath;

    private StaticAnalysisConfig[string] _analysisConfigs;

    void addAnalysisConfigPath(Uri uri)
    {
        _analysisConfigs[uri.path] = defaultStaticAnalysisConfig();
        updateAnalysisConfigPath(uri);
    }

    void removeAnalysisConfigPath(Uri uri)
    {
        if (uri.path in _analysisConfigs)
        {
            _analysisConfigs.remove(uri.path);
        }
    }

    void updateAnalysisConfigPath(Uri uri)
    {
        import dls.protocol.interfaces : PublishDiagnosticsParams;
        import dls.server : Server;
        import dls.util.document : Document;
        import inifiled : readINIFile;
        import std.file : exists;

        auto configPath = buildNormalizedPath(uri.path, _configuration.analysis.configFile);

        if (configPath.exists())
        {
            logf("Updating config from file %s", configPath);
            auto conf = uri.path in _analysisConfigs ? _analysisConfigs[uri.path]
                : defaultStaticAnalysisConfig();
            readINIFile(conf, configPath);
            _analysisConfigs[uri.path] = conf;

            foreach (documentUri; Document.uris)
            {
                Server.send("textDocument/publishDiagnostics",
                        new PublishDiagnosticsParams(documentUri, scan(documentUri)));
            }
        }
    }

    Diagnostic[] scan(Uri uri)
    {
        import dls.protocol.definitions : DiagnosticSeverity;
        import dls.tools.tools : Tools;
        import dls.util.document : Document;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import dscanner.analysis.run : analyze;
        import std.array : appender;
        import std.json : JSONValue;
        import std.typecons : Nullable, nullable;

        logf("Scanning document %s", uri.path);

        auto stringCache = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(Document[uri].toString(),
                LexerConfig(uri.path, StringBehavior.source), &stringCache);
        RollbackAllocator ra;
        auto document = Document[uri];
        auto diagnostics = appender!(Diagnostic[]);

        const syntaxProblemhandler = (string path, size_t line, size_t column,
                string msg, bool isError) {
            diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(line - 1, column - 1), msg, (isError
                    ? DiagnosticSeverity.error : DiagnosticSeverity.warning).nullable,
                    Nullable!JSONValue.init, diagnosticSource.nullable);
        };

        const mod = parseModule(tokens, uri.path, &ra, syntaxProblemhandler);
        const analysisResults = analyze(uri.path, mod, getConfig(uri),
                *Tools.symbolTool.getWorkspaceCache(uri), tokens, true);

        foreach (result; analysisResults)
        {
            diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(result.line - 1, result.column - 1),
                    result.message, DiagnosticSeverity.warning.nullable,
                    JSONValue(result.key).nullable, diagnosticSource.nullable);
        }

        return diagnostics.data;
    }

    private StaticAnalysisConfig getConfig(Uri uri)
    {
        import std.algorithm : startsWith;
        import std.array : array;
        import std.path : pathSplitter;

        string[] configPathParts;

        foreach (path, config; _analysisConfigs)
        {
            auto splitter = pathSplitter(path);

            if (pathSplitter(uri.path).startsWith(splitter))
            {
                auto pathParts = splitter.array;

                if (pathParts.length > configPathParts.length)
                {
                    configPathParts = pathParts;
                }
            }
        }

        const configPath = buildNormalizedPath(configPathParts);
        return (configPath in _analysisConfigs) ? _analysisConfigs[configPath]
            : defaultStaticAnalysisConfig();
    }
}
