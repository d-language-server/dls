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

class AnalysisTool : Tool
{
    import dls.protocol.definitions : Diagnostic, Range;
    import dls.protocol.interfaces : CodeAction, CodeActionKind;
    import dls.util.uri : Uri;
    import dscanner.analysis.config : StaticAnalysisConfig;

    private static AnalysisTool _instance;

    static void initialize()
    {
        _instance = new AnalysisTool();
    }

    static void shutdown()
    {
        destroy(_instance);
    }

    @property static AnalysisTool instance()
    {
        return _instance;
    }

    private StaticAnalysisConfig[string] _analysisConfigs;
    private StaticAnalysisConfig _tempConfig;

    this()
    {
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        _tempConfig = defaultStaticAnalysisConfig();
    }

    void scanAllWorkspaces()
    {
        import dls.protocol.jsonrpc : send;
        import dls.protocol.interfaces : PublishDiagnosticsParams;
        import dls.protocol.messages.methods : Client, TextDocument;
        import dls.tools.symbol_tool : SymbolTool;
        import std.algorithm : each;

        SymbolTool.instance.workspacesFilesUris.each!((uri) {
            send(TextDocument.publishDiagnostics, new PublishDiagnosticsParams(uri,
                AnalysisTool.instance.diagnostics(uri)));
        });
    }

    void addAnalysisConfigPath(in Uri uri)
    {
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        _analysisConfigs[uri.path] = defaultStaticAnalysisConfig();
        updateAnalysisConfigPath(uri);
    }

    void removeAnalysisConfigPath(in Uri uri)
    {
        if (uri.path in _analysisConfigs)
        {
            _analysisConfigs.remove(uri.path);
        }
    }

    void updateAnalysisConfigPath(in Uri uri)
    {
        import dls.util.logger : logger;
        import dscanner.analysis.config : defaultStaticAnalysisConfig;
        import inifiled : readINIFile;
        import std.file : exists;
        import std.path : buildNormalizedPath;

        auto configPath = buildNormalizedPath(uri.path, _configuration.analysis.configFile);

        if (exists(configPath))
        {
            logger.infof("Updating config from file %s", configPath);
            auto conf = uri.path in _analysisConfigs ? _analysisConfigs[uri.path]
                : defaultStaticAnalysisConfig();
            readINIFile(conf, configPath);
            _analysisConfigs[uri.path] = conf;
            scanAllWorkspaces();
        }
        else
        {
            _analysisConfigs.remove(uri.path);
        }
    }

    Diagnostic[] diagnostics(in Uri uri)
    {
        import dls.protocol.definitions : DiagnosticSeverity;
        import dls.tools.symbol_tool : SymbolTool;
        import dls.util.document : Document;
        import dls.util.logger : logger;
        import dparse.lexer : LexerConfig, StringBehavior, StringCache,
            getTokensForParser;
        import dparse.parser : parseModule;
        import dparse.rollback_allocator : RollbackAllocator;
        import dscanner.analysis.run : analyze;
        import std.array : appender;
        import std.json : JSONValue;
        import std.typecons : Nullable, nullable;

        logger.infof("Fetching diagnostics for document %s", uri.path);

        auto stringCache = StringCache(StringCache.defaultBucketCount);
        auto tokens = getTokensForParser(Document.get(uri).toString(),
                LexerConfig(uri.path, StringBehavior.source), &stringCache);
        RollbackAllocator ra;
        auto document = Document.get(uri);
        auto diagnostics = appender!(Diagnostic[]);

        const syntaxProblemhandler = (string path, size_t line, size_t column,
                string msg, bool isError) {
            diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(line - 1, column - 1), msg, (isError
                    ? DiagnosticSeverity.error : DiagnosticSeverity.warning).nullable,
                    Nullable!JSONValue(), diagnosticSource.nullable);
        };

        const mod = parseModule(tokens, uri.path, &ra, syntaxProblemhandler);
        const analysisResults = analyze(uri.path, mod, getConfig(uri),
                SymbolTool.instance.cache, tokens, true);

        foreach (result; analysisResults)
        {
            diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(result.line - 1, result.column - 1),
                    result.message, DiagnosticSeverity.warning.nullable,
                    JSONValue(result.key).nullable, diagnosticSource.nullable);
        }

        return diagnostics.data;
    }

    CodeAction[] codeAction(in Uri uri, in Range range, Diagnostic[] diagnostics,
            in CodeActionKind[] kinds)
    {
        import dls.protocol.definitions : Command, WorkspaceEdit;
        import dls.tools.command_tool : Commands;
        import dls.util.constants : Tr;
        import dls.util.i18n : tr;
        import dls.util.logger : logger;
        import std.algorithm : canFind;
        import std.array : appender;
        import std.json : JSONValue;
        import std.typecons : Nullable, nullable;

        logger.infof("Fetching code actions for document %s at range %s,%s to %s,%s", uri.path,
                range.start.line, range.start.character, range.end.line, range.end.character);

        if (kinds.length > 0 && !kinds.canFind(CodeActionKind.quickfix))
        {
            return [];
        }

        auto result = appender!(CodeAction[]);

        foreach (diagnostic; diagnostics)
        {
            if (!diagnostic.code.isNull)
            {
                auto code = diagnostic.code.get().str;

                if (getDiagnosticParameter(code) !is null)
                {
                    auto title = tr(Tr.app_analysisTool_disableWarning, [code]);
                    auto args = [JSONValue(uri.toString()), JSONValue(code)];
                    auto command = new Command(title,
                            Commands.codeAction_analysis_disableCheck, args.nullable);
                    result ~= new CodeAction(title, CodeActionKind.quickfix.nullable,
                            [diagnostic].nullable, Nullable!WorkspaceEdit(), command.nullable);
                }
            }
        }

        return result.data;
    }

    package void disableCheck(in Uri uri, in string code)
    {
        import dls.tools.symbol_tool : SymbolTool;
        import dscanner.analysis.config : Check;
        import inifiled : INI, writeINIFile;
        import std.path : buildNormalizedPath;

        _tempConfig = getConfig(uri);
        *getDiagnosticParameter(code) = Check.disabled;
        writeINIFile(_tempConfig, buildNormalizedPath(SymbolTool.instance.getWorkspace(uri)
                .path, _configuration.analysis.configFile));
    }

    private StaticAnalysisConfig getConfig(in Uri uri)
    {
        import dls.tools.symbol_tool : SymbolTool;
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        const configUri = SymbolTool.instance.getWorkspace(uri);
        const configPath = configUri is null ? "" : configUri.path;
        return (configPath in _analysisConfigs) ? _analysisConfigs[configPath]
            : defaultStaticAnalysisConfig();
    }

    private string* getDiagnosticParameter(in string code)
    {
        //dfmt off
        switch (code)
        {
        case "dscanner.bugs.backwards_slices"                       : return &_tempConfig.backwards_range_check;
        case "dscanner.bugs.if_else_same"                           : return &_tempConfig.if_else_same_check;
        case "dscanner.bugs.logic_operator_operands"                : return &_tempConfig.if_else_same_check;
        case "dscanner.bugs.self_assignment"                        : return &_tempConfig.if_else_same_check;
        case "dscanner.confusing.argument_parameter_mismatch"       : return &_tempConfig.mismatched_args_check;
        case "dscanner.confusing.brexp"                             : return &_tempConfig.asm_style_check;
        case "dscanner.confusing.builtin_property_names"            : return &_tempConfig.builtin_property_names_check;
        case "dscanner.confusing.constructor_args"                  : return &_tempConfig.constructor_check;
        case "dscanner.confusing.function_attributes"               : return &_tempConfig.function_attribute_check;
        case "dscanner.confusing.lambda_returns_lambda"             : return &_tempConfig.lambda_return_check;
        case "dscanner.confusing.logical_precedence"                : return &_tempConfig.logical_precedence_check;
        case "dscanner.confusing.struct_constructor_default_args"   : return &_tempConfig.constructor_check;
        case "dscanner.deprecated.delete_keyword"                   : return &_tempConfig.delete_check;
        case "dscanner.deprecated.floating_point_operators"         : return &_tempConfig.float_operator_check;
        case "dscanner.if_statement"                                : return &_tempConfig.redundant_if_check;
        case "dscanner.performance.enum_array_literal"              : return &_tempConfig.enum_array_literal_check;
        case "dscanner.style.alias_syntax"                          : return &_tempConfig.alias_syntax_check;
        case "dscanner.style.allman"                                : return &_tempConfig.allman_braces_check;
        case "dscanner.style.assert_without_msg"                    : return &_tempConfig.assert_without_msg;
        case "dscanner.style.doc_missing_params"                    : return &_tempConfig.properly_documented_public_functions;
        case "dscanner.style.doc_missing_returns"                   : return &_tempConfig.properly_documented_public_functions;
        case "dscanner.style.doc_missing_throw"                     : return &_tempConfig.properly_documented_public_functions;
        case "dscanner.style.doc_non_existing_params"               : return &_tempConfig.properly_documented_public_functions;
        case "dscanner.style.explicitly_annotated_unittest"         : return &_tempConfig.explicitly_annotated_unittests;
        case "dscanner.style.has_public_example"                    : return &_tempConfig.has_public_example;
        case "dscanner.style.if_constraints_indent"                 : return &_tempConfig.if_constraints_indent;
        case "dscanner.style.imports_sortedness"                    : return &_tempConfig.imports_sortedness;
        case "dscanner.style.long_line"                             : return &_tempConfig.long_line_check;
        case "dscanner.style.number_literals"                       : return &_tempConfig.number_style_check;
        case "dscanner.style.phobos_naming_convention"              : return &_tempConfig.style_check;
        case "dscanner.style.undocumented_declaration"              : return &_tempConfig.undocumented_declaration_check;
        case "dscanner.suspicious.auto_ref_assignment"              : return &_tempConfig.auto_ref_assignment_check;
        case "dscanner.suspicious.catch_em_all"                     : return &_tempConfig.exception_check;
        case "dscanner.suspicious.comma_expression"                 : return &_tempConfig.comma_expression_check;
        case "dscanner.suspicious.incomplete_operator_overloading"  : return &_tempConfig.opequals_tohash_check;
        case "dscanner.suspicious.incorrect_infinite_range"         : return &_tempConfig.incorrect_infinite_range_check;
        case "dscanner.suspicious.label_var_same_name"              : return &_tempConfig.label_var_same_name_check;
        case "dscanner.suspicious.length_subtraction"               : return &_tempConfig.length_subtraction_check;
        case "dscanner.suspicious.local_imports"                    : return &_tempConfig.local_import_check;
        case "dscanner.suspicious.missing_return"                   : return &_tempConfig.auto_function_check;
        case "dscanner.suspicious.object_const"                     : return &_tempConfig.object_const_check;
        case "dscanner.suspicious.redundant_attributes"             : return &_tempConfig.redundant_attributes_check;
        case "dscanner.suspicious.redundant_parens"                 : return &_tempConfig.redundant_parens_check;
        case "dscanner.suspicious.static_if_else"                   : return &_tempConfig.static_if_else_check;
        case "dscanner.suspicious.unmodified"                       : return &_tempConfig.could_be_immutable_check;
        case "dscanner.suspicious.unused_label"                     : return &_tempConfig.unused_label_check;
        case "dscanner.suspicious.unused_parameter"                 : return &_tempConfig.unused_variable_check;
        case "dscanner.suspicious.unused_variable"                  : return &_tempConfig.unused_variable_check;
        case "dscanner.suspicious.useless_assert"                   : return &_tempConfig.useless_assert_check;
        case "dscanner.suspicious.useless-initializer"              : return &_tempConfig.useless_initializer;
        case "dscanner.trust_too_much"                              : return &_tempConfig.trust_too_much;
        case "dscanner.unnecessary.duplicate_attribute"             : return &_tempConfig.duplicate_attribute;
        case "dscanner.useless.final"                               : return &_tempConfig.final_attribute_check;
        case "dscanner.vcall_ctor"                                  : return &_tempConfig.vcall_in_ctor;
        default                                                     : return null;
        }
        //dfmt on
    }
}
