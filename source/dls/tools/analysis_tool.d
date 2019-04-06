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

module dls.tools.analysis_tool;

import dls.tools.tool : Tool;

private immutable diagnosticSource = "D-Scanner";

//dfmt off
private enum DScannerWarnings : string
{
    bugs_backwardsSlices                        = "dscanner.bugs.backwards_slices",
    bugs_ifElseSame                             = "dscanner.bugs.if_else_same",
    bugs_logicOperatorOperands                  = "dscanner.bugs.logic_operator_operands",
    bugs_selfAssignment                         = "dscanner.bugs.self_assignment",
    confusing_argumentParameter_Mismatch        = "dscanner.confusing.argument_parameter_mismatch",
    confusing_brexp                             = "dscanner.confusing.brexp",
    confusing_builtinPropertyNames              = "dscanner.confusing.builtin_property_names",
    confusing_constructor_args                  = "dscanner.confusing.constructor_args",
    confusing_functionAttributes                = "dscanner.confusing.function_attributes",
    confusing_lambdaReturnsLambda               = "dscanner.confusing.lambda_returns_lambda",
    confusing_logicalPrecedence                 = "dscanner.confusing.logical_precedence",
    confusing_structConstructorDefaultArgs      = "dscanner.confusing.struct_constructor_default_args",
    deprecated_deleteKeyword                    = "dscanner.deprecated.delete_keyword",
    deprecated_floatingPointOperators           = "dscanner.deprecated.floating_point_operators",
    ifStatement                                 = "dscanner.if_statement",
    performance_enumArrayLiteral                = "dscanner.performance.enum_array_literal",
    style_aliasSyntax                           = "dscanner.style.alias_syntax",
    style_allman                                = "dscanner.style.allman",
    style_assertWithoutMsg                      = "dscanner.style.assert_without_msg",
    style_docMissingParams                      = "dscanner.style.doc_missing_params",
    style_docMissingReturns                     = "dscanner.style.doc_missing_returns",
    style_docMissingThrow                       = "dscanner.style.doc_missing_throw",
    style_docNonExistingParams                  = "dscanner.style.doc_non_existing_params",
    style_explicitlyAnnotatedUnittest           = "dscanner.style.explicitly_annotated_unittest",
    style_hasPublicExample                      = "dscanner.style.has_public_example",
    style_ifConstraintsIndent                   = "dscanner.style.if_constraints_indent",
    style_importsSortedness                     = "dscanner.style.imports_sortedness",
    style_longLine                              = "dscanner.style.long_line",
    style_numberLiterals                        = "dscanner.style.number_literals",
    style_phobosNamingConvention                = "dscanner.style.phobos_naming_convention",
    style_undocumentedDeclaration               = "dscanner.style.undocumented_declaration",
    suspicious_autoRefAssignment                = "dscanner.suspicious.auto_ref_assignment",
    suspicious_catchEmAll                       = "dscanner.suspicious.catch_em_all",
    suspicious_commaExpression                  = "dscanner.suspicious.comma_expression",
    suspicious_incompleteOperatorOverloading    = "dscanner.suspicious.incomplete_operator_overloading",
    suspicious_incorrectInfiniteRange           = "dscanner.suspicious.incorrect_infinite_range",
    suspicious_labelVarSameName                 = "dscanner.suspicious.label_var_same_name",
    suspicious_lengthSubtraction                = "dscanner.suspicious.length_subtraction",
    suspicious_localImports                     = "dscanner.suspicious.local_imports",
    suspicious_missingReturn                    = "dscanner.suspicious.missing_return",
    suspicious_objectConst                      = "dscanner.suspicious.object_const",
    suspicious_redundantAttributes              = "dscanner.suspicious.redundant_attributes",
    suspicious_redundantParens                  = "dscanner.suspicious.redundant_parens",
    suspicious_staticIfElse                     = "dscanner.suspicious.static_if_else",
    suspicious_unmodified                       = "dscanner.suspicious.unmodified",
    suspicious_unusedLabel                      = "dscanner.suspicious.unused_label",
    suspicious_unusedParameter                  = "dscanner.suspicious.unused_parameter",
    suspicious_unusedVariable                   = "dscanner.suspicious.unused_variable",
    suspicious_uselessAssert                    = "dscanner.suspicious.useless_assert",
    suspicious_uselessInitializer               = "dscanner.suspicious.useless-initializer",
    trustTooMuch                                = "dscanner.trust_too_much",
    unnecessary_duplicateAttribute              = "dscanner.unnecessary.duplicate_attribute",
    useless_final                               = "dscanner.useless.final",
    vcallCtor                                   = "dscanner.vcall_ctor"
}
//dfmt on

class AnalysisTool : Tool
{
    import dls.protocol.definitions : Command, Diagnostic, Range, TextEdit, WorkspaceEdit;
    import dls.protocol.interfaces : CodeAction, CodeActionKind;
    import dls.util.uri : Uri;
    import dscanner.analysis.config : StaticAnalysisConfig;

    private static AnalysisTool _instance;

    static void initialize(AnalysisTool tool)
    {
        _instance = tool;
        _instance.addConfigHook("configFile", (const Uri uri) {
            if (getConfig(uri).analysis.configFile != _instance._analysisConfigPaths.get(uri.path, ""))
            {
                _instance.updateAnalysisConfig(uri);
            }
        });
        _instance.addConfigHook("filePatterns", (const Uri uri) {
            const newPatterns = getConfig(uri).analysis.filePatterns;

            if (newPatterns != _instance._currentPatterns)
            {
                _instance._currentPatterns = newPatterns.dup;
                _instance.scanAllWorkspaces();
            }
        });
    }

    static void shutdown()
    {
        destroy(_instance);
    }

    @property static AnalysisTool instance()
    {
        return _instance;
    }

    private string[string] _analysisConfigPaths;
    private StaticAnalysisConfig[string] _analysisConfigs;
    private string[] _currentPatterns;

    auto getScannableFilesUris(out Uri[] discardedFiles)
    {
        import dls.tools.symbol_tool : SymbolTool;
        import dls.util.uri : sameFile;
        import std.algorithm : canFind, filter;
        import std.file : SpanMode, dirEntries;
        import std.path : buildPath, globMatch;
        import std.range : chain;

        Uri[] globMatches;
        auto workspacesFilesUris = SymbolTool.instance.workspacesFilesUris;

        foreach (wUri; workspacesUris)
        {
            foreach (entry; dirEntries(wUri.path, SpanMode.depth).filter!q{a.isFile})
            {
                auto entryUri = Uri.fromPath(entry.name);

                foreach (pattern; getConfig(wUri).analysis.filePatterns)
                {
                    if (globMatch(entry.name, buildPath(wUri.path, pattern)))
                    {
                        globMatches ~= entryUri;
                        break;
                    }
                }

                if (!(globMatches.length > 0 && globMatches[$ - 1] is entryUri)
                        && !workspacesFilesUris.canFind!sameFile(entryUri)
                        && globMatch(entry.name, "*.{d,di}"))
                {
                    discardedFiles ~= entryUri;
                }
            }
        }

        return chain(workspacesFilesUris, globMatches);
    }

    void scanAllWorkspaces()
    {
        import dls.protocol.jsonrpc : send;
        import dls.protocol.interfaces : PublishDiagnosticsParams;
        import dls.protocol.messages.methods : TextDocument;
        import std.algorithm : each;

        Uri[] discardedFiles;

        getScannableFilesUris(discardedFiles).each!((uri) {
            import dls.util.disposable_fiber : DisposableFiber;

            DisposableFiber.yield();
            send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri,
                _instance.diagnostics(uri)));
        });

        foreach (file; discardedFiles)
        {
            send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(file, []));
        }
    }

    void addAnalysisConfig(const Uri uri)
    {
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        _analysisConfigs[uri.path] = defaultStaticAnalysisConfig();
        updateAnalysisConfig(uri);
    }

    void removeAnalysisConfig(const Uri workspaceUri)
    {
        _analysisConfigPaths.remove(workspaceUri.path);
        _analysisConfigs.remove(workspaceUri.path);
    }

    void updateAnalysisConfig(const Uri workspaceUri)
    {
        import dls.protocol.logger : logger;
        import dls.server : Server;
        import dscanner.analysis.config : defaultStaticAnalysisConfig;
        import inifiled : readINIFile;
        import std.file : exists;
        import std.path : buildNormalizedPath;

        auto configPath = getAnalysisConfigUri(workspaceUri).path;
        auto conf = defaultStaticAnalysisConfig();

        if (exists(configPath))
        {
            logger.info("Updating config from file %s", configPath);
            readINIFile(conf, configPath);
        }

        _analysisConfigPaths[workspaceUri.path] = configPath;
        _analysisConfigs[workspaceUri.path] = conf;

        if (Server.initialized)
        {
            scanAllWorkspaces();
        }
    }

    Diagnostic[] diagnostics(const Uri uri)
    {
        import dls.protocol.definitions : DiagnosticSeverity;
        import dls.protocol.logger : logger;
        import dls.tools.symbol_tool : SymbolTool;
        import dls.util.document : Document, minusOne;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache, getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import dscanner.analysis.run : analyze;
        import std.array : appender;
        import std.json : JSONValue;
        import std.regex : matchFirst, regex;
        import std.typecons : Nullable, nullable;
        import std.utf : toUTF16;

        logger.info("Fetching diagnostics for %s", uri.path);

        auto stringCache = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(Document.get(uri).toString(),
                LexerConfig(uri.path, StringBehavior.source), &stringCache);
        RollbackAllocator ra;
        auto document = Document.get(uri);
        auto diagnostics = appender!(Diagnostic[]);

        immutable syntaxProblemhandler = (string path, size_t line, size_t column,
                string msg, bool isError) {
            auto severity = (isError ? DiagnosticSeverity.error : DiagnosticSeverity.warning);
            diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(minusOne(line), minusOne(column)), msg,
                    severity.nullable, Nullable!JSONValue(), diagnosticSource.nullable);
        };

        const mod = parseModule(tokens, uri.path, &ra, syntaxProblemhandler);
        const analysisResults = analyze(uri.path, mod, getAnalysisConfig(uri),
                SymbolTool.instance.cache, tokens, true);

        foreach (result; analysisResults)
        {
            if (!document.lines[minusOne(result.line)].matchFirst(
                    regex(`//.*@suppress\s*\(\s*`w ~ result.key.toUTF16() ~ `\s*\)`w)))
            {
                diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(minusOne(result.line),
                        minusOne(result.column)),
                        result.message, DiagnosticSeverity.warning.nullable,
                        JSONValue(result.key).nullable, diagnosticSource.nullable);
            }
        }

        return diagnostics.data;
    }

    Command[] codeAction(const Uri uri, const Range range,
            Diagnostic[] diagnostics, bool commandCompat)
    {
        import dls.protocol.definitions : Position;
        import dls.protocol.logger : logger;
        import dls.tools.command_tool : Commands;
        import dls.util.document : Document;
        import dls.util.i18n : Tr, tr;
        import dls.util.json : convertToJSON;
        import std.algorithm : filter;
        import std.array : appender;
        import std.json : JSONValue;
        import std.string : stripRight;
        import std.typecons : nullable;

        if (commandCompat)
        {
            logger.info("Fetching commands for %s at range %s,%s to %s,%s", uri.path,
                    range.start.line, range.start.character, range.end.line, range.end.character);
        }

        auto result = appender!(Command[]);

        foreach (diagnostic; diagnostics.filter!q{!a.code.isNull})
        {
            StaticAnalysisConfig config;
            auto code = diagnostic.code.get().str;

            if (getDiagnosticParameter(config, code) !is null)
            {
                {
                    auto title = tr(Tr.app_command_diagnostic_disableCheck_local, [code]);
                    auto document = Document.get(uri);
                    auto line = document.lines[diagnostic.range.end.line].stripRight();
                    auto pos = new Position(diagnostic.range.end.line, line.length);
                    auto textEdit = new TextEdit(new Range(pos, pos), " // @suppress(" ~ code ~ ")");
                    auto edit = makeFileWorkspaceEdit(uri, [textEdit]);
                    result ~= new Command(title, Commands.workspaceEdit,
                            [convertToJSON(edit).get()].nullable);
                }

                {
                    auto title = tr(Tr.app_command_diagnostic_disableCheck_global, [code]);
                    auto args = [JSONValue(uri.toString()), JSONValue(code)];
                    result ~= new Command(title,
                            Commands.codeAction_analysis_disableCheck, args.nullable);
                }
            }
        }

        return result.data;
    }

    CodeAction[] codeAction(const Uri uri, const Range range,
            Diagnostic[] diagnostics, const CodeActionKind[] kinds)
    {
        import dls.protocol.definitions : Command, Position;
        import dls.protocol.logger : logger;
        import dls.tools.command_tool : Commands;
        import dls.util.document : Document;
        import dls.util.i18n : Tr, tr;
        import dls.util.json : convertFromJSON;
        import std.algorithm : canFind, filter;
        import std.array : appender;
        import std.typecons : Nullable, nullable;

        logger.info("Fetching code actions for %s at range %s,%s to %s,%s", uri.path,
                range.start.line, range.start.character, range.end.line, range.end.character);

        if (kinds.length > 0 && !kinds.canFind(CodeActionKind.quickfix))
        {
            return [];
        }

        auto result = appender!(CodeAction[]);

        foreach (diagnostic; diagnostics.filter!q{!a.code.isNull})
        {
            foreach (command; codeAction(uri, range, [diagnostic], false))
            {
                auto action = new CodeAction(command.title,
                        CodeActionKind.quickfix.nullable, [diagnostic].nullable);

                if (command.command == Commands.workspaceEdit)
                {
                    action.edit = convertFromJSON!WorkspaceEdit(command.arguments[0]).nullable;
                }
                else
                {
                    action.command = command.nullable;
                }

                result ~= action;
            }
        }

        return result.data;
    }

    package void disableCheck(const Uri uri, const string code)
    {
        import dls.tools.symbol_tool : SymbolTool;
        import dscanner.analysis.config : Check;
        import inifiled : INI, writeINIFile;
        import std.path : buildNormalizedPath;

        auto config = getAnalysisConfig(uri);
        *getDiagnosticParameter(config, code) = Check.disabled;
        writeINIFile(config, _analysisConfigPaths[SymbolTool.instance.getWorkspace(uri).path]);
    }

    private Uri getAnalysisConfigUri(const Uri workspaceUri)
    {
        import std.algorithm : filter, map;
        import std.array : array;
        import std.file : exists;
        import std.path : buildNormalizedPath;

        auto possibleFiles = [getConfig(workspaceUri).analysis.configFile,
            "dscanner.ini", ".dscanner.ini"].map!(
                file => buildNormalizedPath(workspaceUri.path, file));
        return Uri.fromPath((possibleFiles.filter!exists.array ~ buildNormalizedPath(workspaceUri.path,
                "dscanner.ini"))[0]);
    }

    private StaticAnalysisConfig getAnalysisConfig(const Uri uri)
    {
        import dls.tools.symbol_tool : SymbolTool;
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        const workspaceUri = SymbolTool.instance.getWorkspace(uri);
        immutable workspacePath = workspaceUri is null ? "" : workspaceUri.path;
        return _analysisConfigs.get(workspacePath, defaultStaticAnalysisConfig());
    }

    private string* getDiagnosticParameter(return ref StaticAnalysisConfig config, const string code)
    {
        //dfmt off
        switch (code)
        {
        case DScannerWarnings.bugs_backwardsSlices                      : return &config.backwards_range_check;
        case DScannerWarnings.bugs_ifElseSame                           : return &config.if_else_same_check;
        case DScannerWarnings.bugs_logicOperatorOperands                : return &config.if_else_same_check;
        case DScannerWarnings.bugs_selfAssignment                       : return &config.if_else_same_check;
        case DScannerWarnings.confusing_argumentParameter_Mismatch      : return &config.mismatched_args_check;
        case DScannerWarnings.confusing_brexp                           : return &config.asm_style_check;
        case DScannerWarnings.confusing_builtinPropertyNames            : return &config.builtin_property_names_check;
        case DScannerWarnings.confusing_constructor_args                : return &config.constructor_check;
        case DScannerWarnings.confusing_functionAttributes              : return &config.function_attribute_check;
        case DScannerWarnings.confusing_lambdaReturnsLambda             : return &config.lambda_return_check;
        case DScannerWarnings.confusing_logicalPrecedence               : return &config.logical_precedence_check;
        case DScannerWarnings.confusing_structConstructorDefaultArgs    : return &config.constructor_check;
        case DScannerWarnings.deprecated_deleteKeyword                  : return &config.delete_check;
        case DScannerWarnings.deprecated_floatingPointOperators         : return &config.float_operator_check;
        case DScannerWarnings.ifStatement                               : return &config.redundant_if_check;
        case DScannerWarnings.performance_enumArrayLiteral              : return &config.enum_array_literal_check;
        case DScannerWarnings.style_aliasSyntax                         : return &config.alias_syntax_check;
        case DScannerWarnings.style_allman                              : return &config.allman_braces_check;
        case DScannerWarnings.style_assertWithoutMsg                    : return &config.assert_without_msg;
        case DScannerWarnings.style_docMissingParams                    : return &config.properly_documented_public_functions;
        case DScannerWarnings.style_docMissingReturns                   : return &config.properly_documented_public_functions;
        case DScannerWarnings.style_docMissingThrow                     : return &config.properly_documented_public_functions;
        case DScannerWarnings.style_docNonExistingParams                : return &config.properly_documented_public_functions;
        case DScannerWarnings.style_explicitlyAnnotatedUnittest         : return &config.explicitly_annotated_unittests;
        case DScannerWarnings.style_hasPublicExample                    : return &config.has_public_example;
        case DScannerWarnings.style_ifConstraintsIndent                 : return &config.if_constraints_indent;
        case DScannerWarnings.style_importsSortedness                   : return &config.imports_sortedness;
        case DScannerWarnings.style_longLine                            : return &config.long_line_check;
        case DScannerWarnings.style_numberLiterals                      : return &config.number_style_check;
        case DScannerWarnings.style_phobosNamingConvention              : return &config.style_check;
        case DScannerWarnings.style_undocumentedDeclaration             : return &config.undocumented_declaration_check;
        case DScannerWarnings.suspicious_autoRefAssignment              : return &config.auto_ref_assignment_check;
        case DScannerWarnings.suspicious_catchEmAll                     : return &config.exception_check;
        case DScannerWarnings.suspicious_commaExpression                : return &config.comma_expression_check;
        case DScannerWarnings.suspicious_incompleteOperatorOverloading  : return &config.opequals_tohash_check;
        case DScannerWarnings.suspicious_incorrectInfiniteRange         : return &config.incorrect_infinite_range_check;
        case DScannerWarnings.suspicious_labelVarSameName               : return &config.label_var_same_name_check;
        case DScannerWarnings.suspicious_lengthSubtraction              : return &config.length_subtraction_check;
        case DScannerWarnings.suspicious_localImports                   : return &config.local_import_check;
        case DScannerWarnings.suspicious_missingReturn                  : return &config.auto_function_check;
        case DScannerWarnings.suspicious_objectConst                    : return &config.object_const_check;
        case DScannerWarnings.suspicious_redundantAttributes            : return &config.redundant_attributes_check;
        case DScannerWarnings.suspicious_redundantParens                : return &config.redundant_parens_check;
        case DScannerWarnings.suspicious_staticIfElse                   : return &config.static_if_else_check;
        case DScannerWarnings.suspicious_unmodified                     : return &config.could_be_immutable_check;
        case DScannerWarnings.suspicious_unusedLabel                    : return &config.unused_label_check;
        case DScannerWarnings.suspicious_unusedParameter                : return &config.unused_variable_check;
        case DScannerWarnings.suspicious_unusedVariable                 : return &config.unused_variable_check;
        case DScannerWarnings.suspicious_uselessAssert                  : return &config.useless_assert_check;
        case DScannerWarnings.suspicious_uselessInitializer             : return &config.useless_initializer;
        case DScannerWarnings.trustTooMuch                              : return &config.trust_too_much;
        case DScannerWarnings.unnecessary_duplicateAttribute            : return &config.duplicate_attribute;
        case DScannerWarnings.useless_final                             : return &config.final_attribute_check;
        case DScannerWarnings.vcallCtor                                 : return &config.vcall_in_ctor;
        default                                                         : return null;
        }
        //dfmt on
    }

    private WorkspaceEdit makeFileWorkspaceEdit(const Uri uri, TextEdit[] edits)
    {
        import dls.protocol.definitions : TextDocumentEdit, VersionedTextDocumentIdentifier;
        import dls.util.document : Document;
        import std.typecons : nullable;

        auto document = Document.get(uri);
        auto changes = [uri.toString() : edits];
        auto identifier = new VersionedTextDocumentIdentifier(uri, document.version_);
        auto documentChanges = [new TextDocumentEdit(identifier, changes[uri])];
        return new WorkspaceEdit(changes.nullable, documentChanges.nullable);
    }
}
