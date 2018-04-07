module dls.tools.analysis_tool;

import dls.tools.tool : Tool;

private enum diagnosticSource = "D-Scanner";

class AnalysisTool : Tool
{
    import logger = std.experimental.logger;
    import dls.util.uri : Uri;
    import dscanner.analysis.config : StaticAnalysisConfig,
        defaultStaticAnalysisConfig;
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
            logger.logf("Updating config from file %s", configPath);
            auto conf = uri.path in _analysisConfigs ? _analysisConfigs[uri.path]
                : defaultStaticAnalysisConfig();
            readINIFile(conf, configPath);
            _analysisConfigs[uri.path] = conf;

            foreach (documentUri; Document.uris)
            {
                auto diagnosticParams = new PublishDiagnosticsParams();
                diagnosticParams.uri = documentUri;
                diagnosticParams.diagnostics = scan(documentUri);
                Server.send("textDocument/publishDiagnostics", diagnosticParams);
            }
        }
    }

    auto scan(Uri uri)
    {
        import dls.protocol.definitions : Diagnostic, DiagnosticSeverity;
        import dls.tools.tools : Tools;
        import dls.util.document : Document;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
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
        const analysisResults = analyze(uri.path, mod, getConfig(uri),
                Tools.symbolTool.cache, tokens, true);

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

    private auto getConfig(Uri uri)
    {
        import std.algorithm : startsWith;
        import std.array : array;
        import std.path : pathSplitter;

        string[] configPathParts;

        foreach (path, config; _analysisConfigs)
        {
            if (pathSplitter(uri.path).startsWith(pathSplitter(path)))
            {
                auto pathParts = pathSplitter(path).array;

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
