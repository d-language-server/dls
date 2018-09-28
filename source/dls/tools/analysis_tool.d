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
    private string*[string] _diagnosticCodes;

    this()
    {
        import dscanner.analysis.config : defaultStaticAnalysisConfig;

        _tempConfig = defaultStaticAnalysisConfig();
        //dfmt off
        _diagnosticCodes = [
            "dscanner.bugs.backwards_slices"                        : &_tempConfig.backwards_range_check,
            "dscanner.bugs.if_else_same"                            : &_tempConfig.if_else_same_check,
            "dscanner.bugs.logic_operator_operands"                 : &_tempConfig.if_else_same_check,
            "dscanner.bugs.self_assignment"                         : &_tempConfig.if_else_same_check,
            "dscanner.confusing.argument_parameter_mismatch"        : &_tempConfig.mismatched_args_check,
            "dscanner.confusing.brexp"                              : &_tempConfig.asm_style_check,
            "dscanner.confusing.builtin_property_names"             : &_tempConfig.builtin_property_names_check,
            "dscanner.confusing.constructor_args"                   : &_tempConfig.constructor_check,
            "dscanner.confusing.struct_constructor_default_args"    : &_tempConfig.constructor_check,
            "dscanner.confusing.function_attributes"                : &_tempConfig.function_attribute_check,
            "dscanner.confusing.lambda_returns_lambda"              : &_tempConfig.lambda_return_check,
            "dscanner.confusing.logical_precedence"                 : &_tempConfig.logical_precedence_check,
            "dscanner.confusing.struct_constructor_default_args"    : &_tempConfig.constructor_check,
            "dscanner.deprecated.delete_keyword"                    : &_tempConfig.delete_check,
            "dscanner.deprecated.floating_point_operators"          : &_tempConfig.float_operator_check,
            "dscanner.if_statement"                                 : &_tempConfig.redundant_if_check,
            "dscanner.performance.enum_array_literal"               : &_tempConfig.enum_array_literal_check,
            "dscanner.style.alias_syntax"                           : &_tempConfig.alias_syntax_check,
            "dscanner.style.allman"                                 : &_tempConfig.allman_braces_check,
            "dscanner.style.assert_without_msg"                     : &_tempConfig.assert_without_msg,
            "dscanner.style.doc_missing_params"                     : &_tempConfig.properly_documented_public_functions,
            "dscanner.style.doc_missing_returns"                    : &_tempConfig.properly_documented_public_functions,
            "dscanner.style.doc_missing_throw"                      : &_tempConfig.properly_documented_public_functions,
            "dscanner.style.doc_non_existing_params"                : &_tempConfig.properly_documented_public_functions,
            "dscanner.style.explicitly_annotated_unittest"          : &_tempConfig.explicitly_annotated_unittests,
            "dscanner.style.has_public_example"                     : &_tempConfig.has_public_example,
            "dscanner.style.if_constraints_indent"                  : &_tempConfig.if_constraints_indent,
            "dscanner.style.imports_sortedness"                     : &_tempConfig.imports_sortedness,
            "dscanner.style.long_line"                              : &_tempConfig.long_line_check,
            "dscanner.style.number_literals"                        : &_tempConfig.number_style_check,
            "dscanner.style.phobos_naming_convention"               : &_tempConfig.style_check,
            "dscanner.style.undocumented_declaration"               : &_tempConfig.undocumented_declaration_check,
            "dscanner.suspicious.auto_ref_assignment"               : &_tempConfig.auto_ref_assignment_check,
            "dscanner.suspicious.catch_em_all"                      : &_tempConfig.exception_check,
            "dscanner.suspicious.comma_expression"                  : &_tempConfig.comma_expression_check,
            "dscanner.suspicious.incomplete_operator_overloading"   : &_tempConfig.opequals_tohash_check,
            "dscanner.suspicious.incorrect_infinite_range"          : &_tempConfig.incorrect_infinite_range_check,
            "dscanner.suspicious.label_var_same_name"               : &_tempConfig.label_var_same_name_check,
            "dscanner.suspicious.length_subtraction"                : &_tempConfig.length_subtraction_check,
            "dscanner.suspicious.local_imports"                     : &_tempConfig.local_import_check,
            "dscanner.suspicious.missing_return"                    : &_tempConfig.auto_function_check,
            "dscanner.suspicious.object_const"                      : &_tempConfig.object_const_check,
            "dscanner.suspicious.redundant_attributes"              : &_tempConfig.redundant_attributes_check,
            "dscanner.suspicious.redundant_parens"                  : &_tempConfig.redundant_parens_check,
            "dscanner.suspicious.static_if_else"                    : &_tempConfig.static_if_else_check,
            "dscanner.suspicious.unmodified"                        : &_tempConfig.could_be_immutable_check,
            "dscanner.suspicious.unused_label"                      : &_tempConfig.unused_label_check,
            "dscanner.suspicious.unused_parameter"                  : &_tempConfig.unused_variable_check,
            "dscanner.suspicious.unused_variable"                   : &_tempConfig.unused_variable_check,
            "dscanner.suspicious.useless_assert"                    : &_tempConfig.useless_assert_check,
            "dscanner.suspicious.useless-initializer"               : &_tempConfig.useless_initializer,
            "dscanner.trust_too_much"                               : &_tempConfig.trust_too_much,
            "dscanner.unnecessary.duplicate_attribute"              : &_tempConfig.duplicate_attribute,
            "dscanner.useless.final"                                : &_tempConfig.final_attribute_check,
            "dscanner.vcall_ctor"                                   : &_tempConfig.vcall_in_ctor
        ];
        //dfmt on
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

                if (code in _diagnosticCodes)
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
        *_diagnosticCodes[code] = Check.disabled;
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
}
