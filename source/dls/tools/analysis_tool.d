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
        import std.regex : matchFirst, regex;
        import std.typecons : Nullable, nullable;
        import std.utf : toUTF16;

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
            if (!document.lines[result.line - 1].matchFirst(regex(
                    `.*//\s*@suppress\s*\(\s*`w ~ result.key.toUTF16() ~ `\s*\)\s*`w)))
            {
                diagnostics ~= new Diagnostic(document.wordRangeAtLineAndByte(result.line - 1, result.column - 1),
                        result.message, DiagnosticSeverity.warning.nullable,
                        JSONValue(result.key).nullable, diagnosticSource.nullable);
            }
        }

        return diagnostics.data;
    }

    CodeAction[] codeAction(in Uri uri, in Range range, Diagnostic[] diagnostics,
            in CodeActionKind[] kinds)
    {
        import dls.protocol.definitions : Command, Position, TextDocumentEdit,
            TextEdit, VersionedTextDocumentIdentifier, WorkspaceEdit;
        import dls.tools.command_tool : Commands;
        import dls.util.constants : Tr;
        import dls.util.document : Document;
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
                StaticAnalysisConfig config;
                auto code = diagnostic.code.get().str;

                if (getDiagnosticParameter(config, code) !is null)
                {
                    {
                        auto document = Document.get(uri);
                        auto line = document.lines[range.end.line];
                        auto pos = new Position(range.end.line, line.length);

                        auto textEdit = new TextEdit(new Range(pos, pos),
                                " // @suppress(" ~ code ~ ")");
                        auto changes = [uri.toString() : [textEdit]];
                        auto identifier = new VersionedTextDocumentIdentifier(uri,
                                document.version_);
                        auto documentChanges = [new TextDocumentEdit(identifier, changes[uri])];

                        auto title = tr(Tr.app_analysisTool_disableCheck_local, [code]);
                        auto edit = new WorkspaceEdit(changes.nullable, documentChanges.nullable);
                        result ~= new CodeAction(title, CodeActionKind.quickfix.nullable,
                                [diagnostic].nullable, edit.nullable, Nullable!Command());
                    }

                    {
                        auto title = tr(Tr.app_analysisTool_disableCheck_global, [code]);
                        auto args = [JSONValue(uri.toString()), JSONValue(code)];
                        auto command = new Command(title,
                                Commands.codeAction_analysis_disableCheck, args.nullable);
                        result ~= new CodeAction(title, CodeActionKind.quickfix.nullable,
                                [diagnostic].nullable, Nullable!WorkspaceEdit(), command.nullable);
                    }
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

        auto config = getConfig(uri);
        *getDiagnosticParameter(config, code) = Check.disabled;
        writeINIFile(config, buildNormalizedPath(SymbolTool.instance.getWorkspace(uri)
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

    private string* getDiagnosticParameter(ref StaticAnalysisConfig config, in string code)
    {
        //dfmt off
        switch (code)
        {
        case "dscanner.bugs.backwards_slices"                       : return &config.backwards_range_check;
        case "dscanner.bugs.if_else_same"                           : return &config.if_else_same_check;
        case "dscanner.bugs.logic_operator_operands"                : return &config.if_else_same_check;
        case "dscanner.bugs.self_assignment"                        : return &config.if_else_same_check;
        case "dscanner.confusing.argument_parameter_mismatch"       : return &config.mismatched_args_check;
        case "dscanner.confusing.brexp"                             : return &config.asm_style_check;
        case "dscanner.confusing.builtin_property_names"            : return &config.builtin_property_names_check;
        case "dscanner.confusing.constructor_args"                  : return &config.constructor_check;
        case "dscanner.confusing.function_attributes"               : return &config.function_attribute_check;
        case "dscanner.confusing.lambda_returns_lambda"             : return &config.lambda_return_check;
        case "dscanner.confusing.logical_precedence"                : return &config.logical_precedence_check;
        case "dscanner.confusing.struct_constructor_default_args"   : return &config.constructor_check;
        case "dscanner.deprecated.delete_keyword"                   : return &config.delete_check;
        case "dscanner.deprecated.floating_point_operators"         : return &config.float_operator_check;
        case "dscanner.if_statement"                                : return &config.redundant_if_check;
        case "dscanner.performance.enum_array_literal"              : return &config.enum_array_literal_check;
        case "dscanner.style.alias_syntax"                          : return &config.alias_syntax_check;
        case "dscanner.style.allman"                                : return &config.allman_braces_check;
        case "dscanner.style.assert_without_msg"                    : return &config.assert_without_msg;
        case "dscanner.style.doc_missing_params"                    : return &config.properly_documented_public_functions;
        case "dscanner.style.doc_missing_returns"                   : return &config.properly_documented_public_functions;
        case "dscanner.style.doc_missing_throw"                     : return &config.properly_documented_public_functions;
        case "dscanner.style.doc_non_existing_params"               : return &config.properly_documented_public_functions;
        case "dscanner.style.explicitly_annotated_unittest"         : return &config.explicitly_annotated_unittests;
        case "dscanner.style.has_public_example"                    : return &config.has_public_example;
        case "dscanner.style.if_constraints_indent"                 : return &config.if_constraints_indent;
        case "dscanner.style.imports_sortedness"                    : return &config.imports_sortedness;
        case "dscanner.style.long_line"                             : return &config.long_line_check;
        case "dscanner.style.number_literals"                       : return &config.number_style_check;
        case "dscanner.style.phobos_naming_convention"              : return &config.style_check;
        case "dscanner.style.undocumented_declaration"              : return &config.undocumented_declaration_check;
        case "dscanner.suspicious.auto_ref_assignment"              : return &config.auto_ref_assignment_check;
        case "dscanner.suspicious.catch_em_all"                     : return &config.exception_check;
        case "dscanner.suspicious.comma_expression"                 : return &config.comma_expression_check;
        case "dscanner.suspicious.incomplete_operator_overloading"  : return &config.opequals_tohash_check;
        case "dscanner.suspicious.incorrect_infinite_range"         : return &config.incorrect_infinite_range_check;
        case "dscanner.suspicious.label_var_same_name"              : return &config.label_var_same_name_check;
        case "dscanner.suspicious.length_subtraction"               : return &config.length_subtraction_check;
        case "dscanner.suspicious.local_imports"                    : return &config.local_import_check;
        case "dscanner.suspicious.missing_return"                   : return &config.auto_function_check;
        case "dscanner.suspicious.object_const"                     : return &config.object_const_check;
        case "dscanner.suspicious.redundant_attributes"             : return &config.redundant_attributes_check;
        case "dscanner.suspicious.redundant_parens"                 : return &config.redundant_parens_check;
        case "dscanner.suspicious.static_if_else"                   : return &config.static_if_else_check;
        case "dscanner.suspicious.unmodified"                       : return &config.could_be_immutable_check;
        case "dscanner.suspicious.unused_label"                     : return &config.unused_label_check;
        case "dscanner.suspicious.unused_parameter"                 : return &config.unused_variable_check;
        case "dscanner.suspicious.unused_variable"                  : return &config.unused_variable_check;
        case "dscanner.suspicious.useless_assert"                   : return &config.useless_assert_check;
        case "dscanner.suspicious.useless-initializer"              : return &config.useless_initializer;
        case "dscanner.trust_too_much"                              : return &config.trust_too_much;
        case "dscanner.unnecessary.duplicate_attribute"             : return &config.duplicate_attribute;
        case "dscanner.useless.final"                               : return &config.final_attribute_check;
        case "dscanner.vcall_ctor"                                  : return &config.vcall_in_ctor;
        default                                                     : return null;
        }
        //dfmt on
    }
}
