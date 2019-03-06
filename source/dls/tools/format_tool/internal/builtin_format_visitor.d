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

module dls.tools.format_tool.internal.builtin_format_visitor;

import dparse.ast;
import dparse.lexer;

package class BuiltinFormatVisitor : ASTVisitor
{
    size_t[size_t] weakIndentSpans;
    size_t[size_t] indentSpans;
    size_t[] outdents;
    size_t[] unaryOperatorIndexes;
    size_t[] gluedColonIndexes;
    size_t[] starIndexes;
    private size_t[size_t] _firstTokenIndexes;

    this(const Token[] tokens)
    {
        foreach (ref token; tokens)
        {
            _firstTokenIndexes.require(token.line, token.index);
        }
    }

    override void visit(const AliasDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const AliasThisDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const AnonymousEnumDeclaration dec)
    {
        addSpan(dec.baseType);
        super.visit(dec);
    }

    override void visit(const AnonymousEnumMember dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const ArrayMemberInitialization init)
    {
        addWeakSpan(init);
        super.visit(init);
    }

    override void visit(const BreakStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const BaseClassList list)
    {
        addSpan(list);
        super.visit(list);
    }

    override void visit(const CaseRangeStatement stmt)
    {
        gluedColonIndexes ~= stmt.colonLocation;
        const nodes = [stmt.low, stmt.high];
        addWeakSpan(nodes);
        addSpan(nodes);
        super.visit(stmt);
    }

    override void visit(const CaseStatement stmt)
    {
        gluedColonIndexes ~= stmt.colonLocation;
        addWeakSpan(stmt.argumentList);
        addSpan(stmt.argumentList);
        super.visit(stmt);
    }

    override void visit(const Catch c)
    {
        addSpan(c.declarationOrStatement);
        super.visit(c);
    }

    override void visit(const CompileCondition cond)
    {
        addWeakSpan(cond);
        super.visit(cond);
    }

    override void visit(const ConditionalDeclaration dec)
    {
        import std.algorithm : map, sum;
        import std.range : chain;

        auto numTokensLeft = dec.tokens.length - dec.compileCondition.tokens.length - chain(
                dec.trueDeclarations, dec.falseDeclarations).map!q{a.tokens.length}.sum();
        immutable trueDecsHaveBrackets = dec.tokens[dec.compileCondition.tokens.length].type
            == tok!"{";

        if (trueDecsHaveBrackets)
        {
            numTokensLeft -= 2;
        }
        else if (dec.trueDeclarations.length == 1)
        {
            addSpan(dec.trueDeclarations[0]);
        }

        if (dec.hasElse && numTokensLeft < 3 && dec.falseDeclarations.length == 1)
        {
            addSpan(dec.falseDeclarations[0]);
        }

        super.visit(dec);
    }

    override void visit(const ConditionalStatement stmt)
    {
        addSpan(stmt.trueStatement);
        addSpan(stmt.falseStatement);
        super.visit(stmt);
    }

    override void visit(const ContinueStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const DebugSpecification spec)
    {
        addWeakSpan(spec);
        super.visit(spec);
    }

    override void visit(const DefaultStatement stmt)
    {
        gluedColonIndexes ~= stmt.colonLocation;
        super.visit(stmt);
    }

    override void visit(const DeleteStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const DoStatement stmt)
    {
        addSpan(stmt.statementNoCaseNoDefault);
        super.visit(stmt);
    }

    override void visit(const EnumDeclaration dec)
    {
        addSpan(dec.type);
        super.visit(dec);
    }

    override void visit(const EnumMember mem)
    {
        addWeakSpan(mem);
        super.visit(mem);
    }

    override void visit(const EponymousTemplateDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const ExpressionStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const Finally fin)
    {
        addSpan(fin.declarationOrStatement);
        super.visit(fin);
    }

    override void visit(const ForStatement stmt)
    {
        addSpan(stmt.declarationOrStatement);
        super.visit(stmt);
    }

    override void visit(const ForeachStatement stmt)
    {
        addSpan(stmt.declarationOrStatement);
        super.visit(stmt);
    }

    override void visit(const StaticForeachDeclaration dec)
    {
        if (dec.declarations.length == 1
                && dec.declarations[0].tokens[$ - 1].index == dec.tokens[$ - 1].index)
        {
            addSpan(dec.declarations[0]);
        }

        super.visit(dec);
    }

    override void visit(const GotoStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const IfStatement stmt)
    {
        addSpan(stmt.thenStatement);
        addSpan(stmt.elseStatement);
        super.visit(stmt);
    }

    override void visit(const ImportBindings bdgs)
    {
        addWeakSpan(bdgs);
        super.visit(bdgs);
    }

    override void visit(const ImportDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const Initializer init)
    {
        addWeakSpan(init);
        super.visit(init);
    }

    override void visit(const KeyValuePair pair)
    {
        addWeakSpan(pair);
        super.visit(pair);
    }

    override void visit(const LabeledStatement stmt)
    {
        if (stmt.tokens.length > 1)
        {
            gluedColonIndexes ~= stmt.tokens[1].index;
        }

        outdents ~= stmt.tokens[0].line;
        super.visit(stmt);
    }

    override void visit(const LastCatch lc)
    {
        addSpan(lc.statementNoCaseNoDefault);
        super.visit(lc);
    }

    override void visit(const MixinDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const MixinTemplateDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const ModuleDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const Parameter par)
    {
        addWeakSpan(par);
        super.visit(par);
    }

    override void visit(const PragmaDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const PragmaStatement stmt)
    {
        addSpan(stmt.statement);
        super.visit(stmt);
    }

    override void visit(const ReturnStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const ScopeGuardStatement stmt)
    {
        addSpan(stmt.statementNoCaseNoDefault);
        super.visit(stmt);
    }

    override void visit(const StaticAssertStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const StructMemberInitializer init)
    {
        addWeakSpan(init);
        super.visit(init);
    }

    override void visit(const SwitchStatement stmt)
    {
        addSpan(stmt.statement);
        super.visit(stmt);
    }

    override void visit(const SynchronizedStatement stmt)
    {
        addSpan(stmt.statementNoCaseNoDefault);
        super.visit(stmt);
    }

    override void visit(const TemplateParameter par)
    {
        addWeakSpan(par);
        super.visit(par);
    }

    override void visit(const ThrowStatement stmt)
    {
        addWeakSpan(stmt);
        super.visit(stmt);
    }

    override void visit(const TryStatement stmt)
    {
        addSpan(stmt.declarationOrStatement);
        super.visit(stmt);
    }

    override void visit(const TypeSuffix s)
    {
        if (s.star.type != tok!"")
        {
            starIndexes ~= s.star.index;
        }

        super.visit(s);
    }

    override void visit(const UnaryExpression expr)
    {
        foreach (op; [expr.prefix, expr.suffix])
        {
            if (op.type != tok!"")
            {
                unaryOperatorIndexes ~= op.index;
            }
        }

        super.visit(expr);
    }

    override void visit(const VariableDeclaration dec)
    {
        addWeakSpan(dec);
        super.visit(dec);
    }

    override void visit(const VersionSpecification spec)
    {
        addWeakSpan(spec);
        super.visit(spec);
    }

    override void visit(const WhileStatement stmt)
    {
        addSpan(stmt.declarationOrStatement);
        super.visit(stmt);
    }

    override void visit(const WithStatement stmt)
    {
        addSpan(stmt.declarationOrStatement);
        super.visit(stmt);
    }

    private void addWeakSpan(const BaseNode node)
    {
        if (node !is null)
        {
            addWeakSpan([node]);
        }
    }

    private void addWeakSpan(const BaseNode[] nodes)
    {
        addSpanTo(nodes, weakIndentSpans, false);
    }

    private void addSpan(const BaseNode node)
    {
        import std.algorithm : among;

        if (node !is null)
        {
            addSpan([node]);
        }
    }

    private void addSpan(const BaseNode[] nodes)
    {
        import std.algorithm : among;

        if (nodes.length == 0)
        {
            return;
        }

        const t = nodes[0].tokens[0];

        if (t.index == _firstTokenIndexes[t.line] && !t.type.among(tok!"{", tok!"(", tok!"["))
        {
            addSpanTo(nodes, indentSpans, true);
        }
    }

    private void addSpanTo(const BaseNode[] nodes, ref size_t[size_t] spans,
            bool includeStartingLine)
    {
        if (nodes.length == 0)
        {
            return;
        }

        immutable begin = nodes[0].tokens[0].line - (includeStartingLine ? 1 : 0);
        spans.require(begin, nodes[$ - 1].tokens[$ - 1].line + 1);
    }

    alias visit = ASTVisitor.visit;
}
