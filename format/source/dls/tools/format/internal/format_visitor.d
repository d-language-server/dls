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

module dls.tools.format.internal.format_visitor;

import dparse.ast;
import dparse.lexer;
import std.meta : AliasSeq;

private enum builtinTypes = AliasSeq!("bool", "byte", "cdouble", "cent", "cfloat", "char", "creal",
            "dchar", "double", "float", "idouble", "ifloat", "int", "ireal", "long", "real",
            "short", "ubyte", "ucent", "uint", "ulong", "ushort", "void", "wchar");

private enum declarationTypes = AliasSeq!("aliasDeclaration", "aliasThisDeclaration",
            "anonymousEnumDeclaration", "attributeDeclaration", "classDeclaration",
            "conditionalDeclaration", "constructor", "debugSpecification",
            "destructor", "enumDeclaration", "eponymousTemplateDeclaration", "functionDeclaration",
            "importDeclaration", "interfaceDeclaration", "invariant_",
            "mixinDeclaration", "mixinTemplateDeclaration", "postblit",
            "pragmaDeclaration", "sharedStaticConstructor", "sharedStaticDestructor",
            "staticAssertDeclaration",
            "staticConstructor",
            "staticDestructor", "structDeclaration", "staticForeachDeclaration",
            "templateDeclaration", "unionDeclaration", "unittest_",
            "variableDeclaration", "versionSpecification");

private enum Style
{
    newLine,
    spaceBefore,
    spaceAfter,
    none
}

private enum BraceKind
{
    start,
    end,
    empty
}

package(dls.tools.format) struct TokenInfo
{
    import dls.tools.format.internal.util : RollbackRange;

    RollbackRange!bool emptyLines;

    void save()
    {
        import std.traits : isSomeFunction;

        foreach (member; __traits(allMembers, typeof(this)))
        {
            static if (!isSomeFunction!(__traits(getMember, typeof(this), member)))
                mixin(member ~ ".index.save();");
        }
    }

    void load()
    {
        import std.traits : isSomeFunction;

        foreach (member; __traits(allMembers, typeof(this)))
        {
            static if (!isSomeFunction!(__traits(getMember, typeof(this), member)))
                mixin(member ~ ".index.load();");
        }
    }
}

package(dls.tools.format) class FormatVisitor : ASTVisitor
{
    import dls.tools.format.internal.config : FormatConfig, IndentStyle;
    import dls.tools.format.internal.util : Memento, RollbackRange;
    import std.container : SList;
    import std.outbuffer : OutBuffer;

    private Memento!OutBuffer _result;
    private const(Token)[] _inputTokens;
    private FormatConfig _config;
    private size_t _indentLevel;
    private size_t _tempIndentLevel;
    private Memento!size_t _lineLength;
    private SList!Style _styles;
    private size_t _inlineDepth;
    private TokenInfo _tokenInfo;

    @property OutBuffer result()
    {
        return _result.data;
    }

    this(const Token[] inputTokens, const FormatConfig config, TokenInfo tokenInfo)
    {
        import dls.tools.format.internal.config : EndOfLine;
        import std.algorithm : filter;
        import std.array : array;

        _result.data = new OutBuffer();
        _inputTokens = inputTokens.filter!(t => t.type == tok!"comment").array;
        _config = config;
        _styles.insertFront(Style.none);
        _tokenInfo = tokenInfo;

        if (_config.endOfLine == EndOfLine.osDefault)
        {
            version (Windows)
                _config.endOfLine = EndOfLine.crlf;
            else
                _config.endOfLine = EndOfLine.lf;
        }
    }

    // DONE
    override void visit(const ExpressionNode expressionNode)
    {
        super.visit(expressionNode);
    }

    // DONE
    override void visit(const AddExpression addExpression)
    {
        tryVisit(addExpression.left);
        writef(" %s ", str(addExpression.operator));
        tryVisit(addExpression.right);
    }

    // TODO
    override void visit(const AliasDeclaration aliasDeclaration)
    {
        tryVisit(aliasDeclaration.storageClasses);
    }

    // TODO
    override void visit(const AliasInitializer aliasInitializer)
    {
        super.visit(aliasInitializer);
    }

    // DONE
    override void visit(const AliasThisDeclaration aliasThisDeclaration)
    {
        write("alias ");
        visit(aliasThisDeclaration.identifier);
        write(" this");
        writeSemicolon();
    }

    // TODO
    override void visit(const AlignAttribute alignAttribute)
    {
        super.visit(alignAttribute);
    }

    // DONE
    override void visit(const AndAndExpression andAndExpression)
    {
        visit(andAndExpression.left);
        write(" && ");
        visit(andAndExpression.right);
    }

    // DONE
    override void visit(const AndExpression andExpression)
    {
        visit(andExpression.left);
        write(" & ");
        visit(andExpression.right);
    }

    // DONE
    override void visit(const AnonymousEnumDeclaration anonymousEnumDeclaration)
    {
        writeEnumHeader(null, anonymousEnumDeclaration.baseType);
        writeEnumBody(anonymousEnumDeclaration.members);
    }

    // DONE
    override void visit(const AnonymousEnumMember anonymousEnumMember)
    {
        writeEnumMember(anonymousEnumMember);
    }

    // DONE
    override void visit(const ArgumentList argumentList)
    {
        write('(');
        writeList(argumentList.items);
        write(')');
    }

    // TODO
    override void visit(const Arguments arguments)
    {
        super.visit(arguments);
    }

    // TODO
    override void visit(const ArrayInitializer arrayInitializer)
    {
        super.visit(arrayInitializer);
    }

    // TODO
    override void visit(const ArrayLiteral arrayLiteral)
    {
        super.visit(arrayLiteral);
    }

    // TODO
    override void visit(const ArrayMemberInitialization arrayMemberInitialization)
    {
        super.visit(arrayMemberInitialization);
    }

    // TODO
    override void visit(const AsmAddExp asmAddExp)
    {
        super.visit(asmAddExp);
    }

    // TODO
    override void visit(const AsmAndExp asmAndExp)
    {
        super.visit(asmAndExp);
    }

    // TODO
    override void visit(const AsmBrExp asmBrExp)
    {
        super.visit(asmBrExp);
    }

    // TODO
    override void visit(const AsmEqualExp asmEqualExp)
    {
        super.visit(asmEqualExp);
    }

    // TODO
    override void visit(const AsmExp asmExp)
    {
        super.visit(asmExp);
    }

    // TODO
    override void visit(const AsmInstruction asmInstruction)
    {
        super.visit(asmInstruction);
    }

    // TODO
    override void visit(const AsmLogAndExp asmLogAndExp)
    {
        super.visit(asmLogAndExp);
    }

    // TODO
    override void visit(const AsmLogOrExp asmLogOrExp)
    {
        super.visit(asmLogOrExp);
    }

    // TODO
    override void visit(const AsmMulExp asmMulExp)
    {
        super.visit(asmMulExp);
    }

    // TODO
    override void visit(const AsmOrExp asmOrExp)
    {
        super.visit(asmOrExp);
    }

    // TODO
    override void visit(const AsmPrimaryExp asmPrimaryExp)
    {
        super.visit(asmPrimaryExp);
    }

    // TODO
    override void visit(const AsmRelExp asmRelExp)
    {
        super.visit(asmRelExp);
    }

    // TODO
    override void visit(const AsmShiftExp asmShiftExp)
    {
        super.visit(asmShiftExp);
    }

    // TODO
    override void visit(const AsmStatement asmStatement)
    {
        super.visit(asmStatement);
    }

    // TODO
    override void visit(const AsmTypePrefix asmTypePrefix)
    {
        super.visit(asmTypePrefix);
    }

    // TODO
    override void visit(const AsmUnaExp asmUnaExp)
    {
        super.visit(asmUnaExp);
    }

    // TODO
    override void visit(const AsmXorExp asmXorExp)
    {
        super.visit(asmXorExp);
    }

    // DONE
    override void visit(const AssertArguments assertArguments)
    {
        visit(assertArguments.assertion);

        if (assertArguments.message !is null)
        {
            write(", ");
            visit(assertArguments.message);
        }
    }

    // DONE
    override void visit(const AssertExpression assertExpression)
    {
        write("assert(");
        tryVisit(assertExpression.assertArguments);
        write(')');
    }

    // DONE
    override void visit(const AssignExpression assignExpression)
    {
        tryVisit(assignExpression.ternaryExpression);
        writef(" %s ", str(assignExpression.operator));
        tryVisit(assignExpression.expression);
    }

    // TODO
    override void visit(const AssocArrayLiteral assocArrayLiteral)
    {
        super.visit(assocArrayLiteral);
    }

    // TODO
    override void visit(const AtAttribute atAttribute)
    {
        write('@');

        if (atAttribute.argumentList is null && atAttribute.templateInstance is null)
            visit(atAttribute.identifier);

        super.visit(atAttribute);
    }

    // TODO
    override void visit(const Attribute attribute)
    {
        writeCurrentStyle(true);

        if (attribute.attribute != tok!"")
            visit(attribute.attribute);

        super.visit(attribute);

        if (attribute.identifierChain !is null)
        {
            write('(');
            visit(attribute.identifierChain);
            write(')');
        }

        writeCurrentStyle(false);
    }

    // TODO
    override void visit(const AttributeDeclaration attributeDeclaration)
    {
        _styles.insertFront(Style.none);
        super.visit(attributeDeclaration);
        _styles.removeFront();
        write(':');
        writeNewLine();
    }

    // DONE
    override void visit(const AutoDeclaration autoDeclaration)
    {
        tryVisit(autoDeclaration.storageClasses);
        writeList(autoDeclaration.parts);
    }

    // TODO
    override void visit(const AutoDeclarationPart autoDeclarationPart)
    {
        visit(autoDeclarationPart.identifier);
        visit(autoDeclarationPart.initializer);
    }

    // DONE
    override void visit(const BlockStatement blockStatement)
    {
        if (blockStatement.declarationsAndStatements !is null
                && blockStatement.declarationsAndStatements.declarationsAndStatements.length > 0)
        {
            writeBraces(BraceKind.start);
            visit(blockStatement.declarationsAndStatements);
            writeBraces(BraceKind.end);
        }
        else
            writeBraces(BraceKind.empty);
    }

    // TODO
    override void visit(const BreakStatement breakStatement)
    {
        super.visit(breakStatement);
    }

    // DONE
    override void visit(const BaseClass baseClass)
    {
        super.visit(baseClass);
    }

    // TODO
    override void visit(const BaseClassList baseClassList)
    {
        if (baseClassList.items.length == 0)
            return;

        write(" :");
        beginTransaction();
        write(' ');
        visit(baseClassList.items[0]);

        if (baseClassList.items.length == 1)
        {
            commitTransaction();
            return;
        }

        const inlineFirstClass = canAddToCurrentLine(1);
        cancelTransaction();

        if (inlineFirstClass)
            write(' ');
        else
        {
            ++_tempIndentLevel;
            writeNewLine();
            writeIndents();
            --_tempIndentLevel;
        }

        writeList(baseClassList.items);
    }

    // TODO
    override void visit(const CaseRangeStatement caseRangeStatement)
    {
        super.visit(caseRangeStatement);
    }

    // TODO
    override void visit(const CaseStatement caseStatement)
    {
        super.visit(caseStatement);
    }

    // DONE
    override void visit(const CastExpression castExpression)
    {
        write("cast(");
        tryVisit(castExpression.type);
        tryVisit(castExpression.castQualifier);
        write(") ");
        visit(castExpression.unaryExpression);
    }

    // TODO
    override void visit(const CastQualifier castQualifier)
    {
        super.visit(castQualifier);
    }

    // TODO
    override void visit(const Catch catch_)
    {
        super.visit(catch_);
    }

    // TODO
    override void visit(const Catches catches)
    {
        super.visit(catches);
    }

    // TODO
    override void visit(const ClassDeclaration classDeclaration)
    {
        write("class ");
        visit(classDeclaration.name);
        tryVisit(classDeclaration.templateParameters);
        tryVisit(classDeclaration.baseClassList);

        if (classDeclaration.constraint !is null)
        {
            ++_indentLevel;
            writeNewLine();
            writeIndents();
            write("if (");
            visit(classDeclaration.constraint);
            write(')');
            --_indentLevel;
        }

        if (classDeclaration.structBody is null)
            writeSemicolon();
        else
            visit(classDeclaration.structBody);
    }

    // DONE
    override void visit(const CmpExpression cmpExpression)
    {
        super.visit(cmpExpression);
    }

    // TODO
    override void visit(const CompileCondition compileCondition)
    {
        super.visit(compileCondition);
    }

    // TODO
    override void visit(const ConditionalDeclaration conditionalDeclaration)
    {
        super.visit(conditionalDeclaration);
    }

    // TODO
    override void visit(const ConditionalStatement conditionalStatement)
    {
        super.visit(conditionalStatement);
    }

    // DONE
    override void visit(const Constraint constraint)
    {
        super.visit(constraint);
    }

    // TODO
    override void visit(const Constructor constructor)
    {
        super.visit(constructor);
    }

    // TODO
    override void visit(const ContinueStatement continueStatement)
    {
        super.visit(continueStatement);
    }

    // TODO
    override void visit(const DebugCondition debugCondition)
    {
        super.visit(debugCondition);
    }

    // TODO
    override void visit(const DebugSpecification debugSpecification)
    {
        super.visit(debugSpecification);
    }

    // DONE
    override void visit(const Declaration declaration)
    {
        writeIndents();

        foreach (field; declarationTypes)
        {
            if (mixin("declaration." ~ field) !is null)
            {
                writeAttributes(declaration.attributes);
                visit(mixin("declaration." ~ field));
                return;
            }
        }

        if (declaration.attributes !is null)
        {
            foreach (attr; declaration.attributes)
            {
                _styles.insertFront(attr is declaration.attributes[0]
                        ? Style.none : Style.spaceBefore);
                visit(attr);
                _styles.removeFront();
            }
        }

        if (declaration.attributes.length > 0 || declaration.declarations.length > 0)
        {
            if (declaration.declarations.length > 0)
            {
                writeBraces(BraceKind.start);
                tryVisit(declaration.declarations);
                writeBraces(BraceKind.end);
            }
            else
                writeBraces(BraceKind.empty);
        }
        else
            writeSemicolon();
    }

    // DONE
    override void visit(const DeclarationOrStatement declarationsOrStatement)
    {
        super.visit(declarationsOrStatement);
    }

    // DONE
    override void visit(const DeclarationsAndStatements declarationsAndStatements)
    {
        super.visit(declarationsAndStatements);
    }

    // DONE
    override void visit(const Declarator declarator)
    {
        tryVisit(declarator.cstyle);
        visit(declarator.name);
        tryVisit(declarator.templateParameters);
        tryVisit(declarator.initializer);
    }

    // TODO
    override void visit(const DefaultStatement defaultStatement)
    {
        super.visit(defaultStatement);
    }

    // DONE
    override void visit(const DeleteExpression deleteExpression)
    {
        write("delete ");
        visit(deleteExpression.unaryExpression);
    }

    // DONE
    override void visit(const DeleteStatement deleteStatement)
    {
        visit(deleteStatement.deleteExpression);
        writeSemicolon();
    }

    // DONE
    override void visit(const Deprecated deprecated_)
    {
        write("deprecated");

        if (deprecated_.assignExpression !is null)
        {
            write('(');
            visit(deprecated_.assignExpression);
            write(')');
        }
    }

    // TODO
    override void visit(const Destructor destructor)
    {
        super.visit(destructor);
    }

    // TODO
    override void visit(const DoStatement doStatement)
    {
        super.visit(doStatement);
    }

    // DONE
    override void visit(const EnumBody enumBody)
    {
        writeEnumMembers(enumBody.enumMembers);
    }

    // DONE
    override void visit(const EnumDeclaration enumDeclaration)
    {
        writeEnumHeader(enumDeclaration.name.text, enumDeclaration.type);

        if (enumDeclaration.enumBody is null)
            writeSemicolon();
        else
            writeEnumBody(enumDeclaration.enumBody.enumMembers);
    }

    // DONE
    override void visit(const EnumMember enumMember)
    {
        tryVisit(enumMember.enumMemberAttributes);
        writeEnumMember(enumMember);
    }

    // DONE
    override void visit(const EnumMemberAttribute enumMemberAttribute)
    {
        super.visit(enumMemberAttribute);
        write(' ');
    }

    // TODO
    override void visit(const EponymousTemplateDeclaration eponymousTemplateDeclaration)
    {
        super.visit(eponymousTemplateDeclaration);
    }

    // TODO
    override void visit(const EqualExpression equalExpression)
    {
        visit(equalExpression.left);
        writef(" %s ", str(equalExpression.operator));
        visit(equalExpression.right);
    }

    // TODO
    override void visit(const Expression expression)
    {
        super.visit(expression);
    }

    // TODO
    override void visit(const ExpressionStatement expressionStatement)
    {
        writeIndents();
        super.visit(expressionStatement);
        writeSemicolon();
    }

    // TODO
    override void visit(const FinalSwitchStatement finalSwitchStatement)
    {
        super.visit(finalSwitchStatement);
    }

    // TODO
    override void visit(const Finally finally_)
    {
        super.visit(finally_);
    }

    // TODO
    override void visit(const ForStatement forStatement)
    {
        super.visit(forStatement);
    }

    // TODO
    override void visit(const ForeachStatement foreachStatement)
    {
        super.visit(foreachStatement);
    }

    // TODO
    override void visit(const StaticForeachDeclaration staticForeachDeclaration)
    {
        super.visit(staticForeachDeclaration);
    }

    // TODO
    override void visit(const StaticForeachStatement staticForeachStatement)
    {
        super.visit(staticForeachStatement);
    }

    // TODO
    override void visit(const ForeachType foreachType)
    {
        super.visit(foreachType);
    }

    // TODO
    override void visit(const ForeachTypeList foreachTypeList)
    {
        super.visit(foreachTypeList);
    }

    // TODO
    override void visit(const FunctionAttribute functionAttribute)
    {
        write(' ');
        super.visit(functionAttribute);
    }

    // DONE
    override void visit(const FunctionBody functionBody)
    {
        super.visit(functionBody);
    }

    // TODO
    override void visit(const FunctionCallExpression functionCallExpression)
    {
        super.visit(functionCallExpression);
    }

    // DONE
    override void visit(const FunctionContract functionContract)
    {
        super.visit(functionContract);
    }

    // TODO
    override void visit(const FunctionDeclaration functionDeclaration)
    {
        if (functionDeclaration.hasAuto)
            write("auto ");

        if (functionDeclaration.hasRef)
            write("ref ");

        tryVisit(functionDeclaration.storageClasses);
        visit(functionDeclaration.returnType);
        write(' ');
        visit(functionDeclaration.name);
        tryVisit(functionDeclaration.templateParameters);
        tryVisit(functionDeclaration.parameters);
        tryVisit(functionDeclaration.attributes);
        tryVisit(functionDeclaration.memberFunctionAttributes);

        if (functionDeclaration.constraint !is null)
        {
            writeNewLine();
            ++_indentLevel;
            visit(functionDeclaration.constraint);
            --_indentLevel;
            writeNewLine();
        }

        if (functionDeclaration.functionBody is null)
            writeSemicolon();
        else
            visit(functionDeclaration.functionBody);
    }

    // TODO
    override void visit(const FunctionLiteralExpression functionLiteralExpression)
    {
        super.visit(functionLiteralExpression);
    }

    // TODO
    override void visit(const GotoStatement gotoStatement)
    {
        super.visit(gotoStatement);
    }

    // DONE
    override void visit(const IdentifierChain identifierChain)
    {
        foreach (i, identifier; identifierChain.identifiers)
        {
            if (i > 0)
                write('.');

            visit(identifier);
        }
    }

    // TODO
    override void visit(const DeclaratorIdentifierList identifierList)
    {
        super.visit(identifierList);
    }

    // TODO
    override void visit(const IdentifierOrTemplateChain identifierOrTemplateChain)
    {
        super.visit(identifierOrTemplateChain);
    }

    // TODO
    override void visit(const IdentifierOrTemplateInstance identifierOrTemplateInstance)
    {
        super.visit(identifierOrTemplateInstance);
    }

    // DONE
    override void visit(const IdentityExpression identityExpression)
    {
        visit(identityExpression.left);
        writef(" %sis ", identityExpression.negated ? "!" : "");
        visit(identityExpression.right);
    }

    // TODO
    override void visit(const IfStatement ifStatement)
    {
        static bool isBlockOrIf(const DeclarationOrStatement dos)
        {
            return dos.statement !is null && dos.statement.statementNoCaseNoDefault !is null
                && (dos.statement.statementNoCaseNoDefault.blockStatement !is null
                        || dos.statement.statementNoCaseNoDefault.ifStatement !is null);
        }

        void visitDOS(const DeclarationOrStatement dos)
        {
            if (!isBlockOrIf(dos))
            {
                writeNewLine();
                ++_indentLevel;
            }

            visit(dos);

            if (!isBlockOrIf(dos))
                --_indentLevel;
        }

        writeIndents();
        write("if (");

        if (ifStatement.identifier.type != tok!"")
        {
            if (ifStatement.typeCtors.length > 0)
            {
                foreach (ctor; ifStatement.typeCtors)
                    if (ctor != tok!"")
                        writef("%s ", str(ctor));
            }
            else if (ifStatement.type is null)
                write("auto ");

            if (ifStatement.type !is null)
            {
                visit(ifStatement.type);
                write(' ');
            }

            visit(ifStatement.identifier);
            write(" = ");
        }

        visit(ifStatement.expression);
        write(')');
        visitDOS(ifStatement.thenStatement);

        if (ifStatement.elseStatement !is null)
        {
            writeIndents();
            write("else");
            visitDOS(ifStatement.elseStatement);
        }
    }

    // DONE
    override void visit(const ImportBind importBind)
    {
        if (importBind.right.type != tok!"")
        {
            visit(importBind.left);
            write(" = ");
            visit(importBind.right);
        }
        else
            visit(importBind.left);
    }

    // DONE
    override void visit(const ImportBindings importBindings)
    {
        visit(importBindings.singleImport);
        write(" :");
        ++_tempIndentLevel;

        foreach (i, importBind; importBindings.importBinds)
        {
            if (i > 0)
                write(',');

            beginTransaction();
            write(' ');
            visit(importBind);

            if (canAddToCurrentLine(1))
                commitTransaction();
            else
            {
                cancelTransaction();
                writeNewLine();
                writeIndents();
                visit(importBind);
            }
        }
    }

    // DONE
    override void visit(const ImportDeclaration importDeclaration)
    {
        write("import ");

        if (importDeclaration.singleImports.length > 0)
            ++_tempIndentLevel;

        foreach (singleImport; importDeclaration.singleImports)
        {
            visit(singleImport);

            if (singleImport == importDeclaration.singleImports[$ - 1]
                    && importDeclaration.importBindings is null)
                break;

            write(',');
            writeNewLine();
            writeIndents();
        }

        if (importDeclaration.importBindings !is null)
            visit(importDeclaration.importBindings);

        writeSemicolon();
    }

    // DONE
    override void visit(const ImportExpression importExpression)
    {
        write("import(");
        visit(importExpression.assignExpression);
        write(")");
    }

    // TODO
    override void visit(const IndexExpression indexExpression)
    {
        super.visit(indexExpression);
    }

    // TODO
    override void visit(const InContractExpression inContractExpression)
    {
        super.visit(inContractExpression);
    }

    // TODO
    override void visit(const InExpression inExpression)
    {
        visit(inExpression.left);
        writef(" %sin ", inExpression.negated ? "!" : "");
        visit(inExpression.right);
    }

    // DONE
    override void visit(const InOutContractExpression inOutContractExpression)
    {
        super.visit(inOutContractExpression);
    }

    // DONE
    override void visit(const InOutStatement inOutStatement)
    {
        super.visit(inOutStatement);
    }

    // TODO
    override void visit(const InStatement inStatement)
    {
        super.visit(inStatement);
    }

    // TODO
    override void visit(const Initialize initialize)
    {
        super.visit(initialize);
    }

    // DONE
    override void visit(const Initializer initializer)
    {
        write(" = ");

        if (initializer.nonVoidInitializer is null)
            write("void");
        else
            visit(initializer.nonVoidInitializer);
    }

    // TODO
    override void visit(const InterfaceDeclaration interfaceDeclaration)
    {
        super.visit(interfaceDeclaration);
    }

    // TODO
    override void visit(const Invariant invariant_)
    {
        super.visit(invariant_);
    }

    // TODO
    override void visit(const IsExpression isExpression)
    {
        super.visit(isExpression);
    }

    // TODO
    override void visit(const KeyValuePair keyValuePair)
    {
        super.visit(keyValuePair);
    }

    // TODO
    override void visit(const KeyValuePairs keyValuePairs)
    {
        super.visit(keyValuePairs);
    }

    // TODO
    override void visit(const LabeledStatement labeledStatement)
    {
        super.visit(labeledStatement);
    }

    // TODO
    override void visit(const LastCatch lastCatch)
    {
        super.visit(lastCatch);
    }

    // TODO
    override void visit(const LinkageAttribute linkageAttribute)
    {
        writef("extern (%s%s", linkageAttribute.identifier.text,
                linkageAttribute.hasPlusPlus ? "++" : "");

        if (linkageAttribute.typeIdentifierPart !is null)
        {
            write(", ");
            visit(linkageAttribute.typeIdentifierPart);
        }

        write(')');
    }

    // DONE
    override void visit(const MemberFunctionAttribute memberFunctionAttribute)
    {
        write(' ');

        if (memberFunctionAttribute.tokenType != tok!"")
            write(str(memberFunctionAttribute.tokenType));

        tryVisit(memberFunctionAttribute.atAttribute);
    }

    // DONE
    override void visit(const MissingFunctionBody missingFunctionBody)
    {
        tryVisit(missingFunctionBody.functionContracts);
        writeSemicolon();
    }

    // TODO
    override void visit(const MixinDeclaration mixinDeclaration)
    {
        super.visit(mixinDeclaration);
    }

    // TODO
    override void visit(const MixinExpression mixinExpression)
    {
        super.visit(mixinExpression);
    }

    // TODO
    override void visit(const MixinTemplateDeclaration mixinTemplateDeclaration)
    {
        super.visit(mixinTemplateDeclaration);
    }

    // TODO
    override void visit(const MixinTemplateName mixinTemplateName)
    {
        super.visit(mixinTemplateName);
    }

    // DONE
    override void visit(const Module module_)
    {
        if (module_.scriptLine.text.length > 0)
        {
            visit(module_.scriptLine);
            writeNewLine();
        }

        tryVisit(module_.moduleDeclaration);
        tryVisit(module_.declarations);
    }

    // DONE
    override void visit(const ModuleDeclaration moduleDeclaration)
    {
        writeIndents();
        tryVisit(moduleDeclaration.deprecated_);
        writeNewLine();
        writeIndents();
        write("module ");
        visit(moduleDeclaration.moduleName);
        writeSemicolon();
    }

    // TODO
    override void visit(const MulExpression mulExpression)
    {
        tryVisit(mulExpression.left);
        writef(" %s ", str(mulExpression.operator));
        tryVisit(mulExpression.right);
    }

    // TODO
    override void visit(const NewAnonClassExpression newAnonClassExpression)
    {
        super.visit(newAnonClassExpression);
    }

    // TODO
    override void visit(const NewExpression newExpression)
    {
        super.visit(newExpression);
    }

    // DONE
    override void visit(const NonVoidInitializer nonVoidInitializer)
    {
        super.visit(nonVoidInitializer);
    }

    // TODO
    override void visit(const Operands operands)
    {
        super.visit(operands);
    }

    // DONE
    override void visit(const OrExpression orExpression)
    {
        visit(orExpression.left);
        write(" | ");
        visit(orExpression.right);
    }

    // DONE
    override void visit(const OrOrExpression orOrExpression)
    {
        visit(orOrExpression.left);
        write(" || ");
        visit(orOrExpression.right);
    }

    // TODO
    override void visit(const OutContractExpression outContractExpression)
    {
        super.visit(outContractExpression);
    }

    // TODO
    override void visit(const OutStatement outStatement)
    {
        super.visit(outStatement);
    }

    // TODO
    override void visit(const ParameterAttribute parameterAttribute)
    {
        if (parameterAttribute.idType != tok!"")
            write(str(parameterAttribute.idType));

        super.visit(parameterAttribute);
        write(' ');
    }

    // DONE
    override void visit(const Parameter parameter)
    {
        tryVisit(parameter.parameterAttributes);
        visit(parameter.type);

        if (parameter.name != tok!"")
        {
            write(' ');
            visit(parameter.name);
        }

        if (parameter.vararg)
            write("...");

        if (parameter.default_ !is null)
        {
            write(" = ");
            visit(parameter.default_);
        }
    }

    // DONE
    override void visit(const Parameters parameters)
    {
        write('(');
        writeList(parameters.parameters);
        write(')');
    }

    // TODO
    override void visit(const Postblit postblit)
    {
        super.visit(postblit);
    }

    // TODO
    override void visit(const PowExpression powExpression)
    {
        super.visit(powExpression);
    }

    // DONE
    override void visit(const PragmaDeclaration pragmaDeclaration)
    {
        visit(pragmaDeclaration.pragmaExpression);
        writeSemicolon();
    }

    // DONE
    override void visit(const PragmaExpression pragmaExpression)
    {
        write("pragma(");
        visit(pragmaExpression.identifier);

        if (pragmaExpression.argumentList !is null)
            writeList(pragmaExpression.argumentList.items, true);

        write(")");
    }

    // TODO
    override void visit(const PragmaStatement pragmaStatement)
    {
        visit(pragmaStatement.pragmaExpression);

        if (pragmaStatement.statement !is null)
        {
            ++_tempIndentLevel;
            visit(pragmaStatement.statement);
            writeSemicolon();
        }
        else
            visit(pragmaStatement.blockStatement);
    }

    // TODO
    override void visit(const PrimaryExpression primaryExpression)
    {
        if (primaryExpression.expression !is null)
            write('(');
        super.visit(primaryExpression);
        if (primaryExpression.expression !is null)
            write(')');
    }

    // TODO
    override void visit(const Register register)
    {
        super.visit(register);
    }

    // TODO
    override void visit(const RelExpression relExpression)
    {
        visit(relExpression.left);
        writef(" %s ", str(relExpression.operator));
        visit(relExpression.right);
    }

    // TODO
    override void visit(const ReturnStatement returnStatement)
    {
        writeIndents();
        write("return");

        if (returnStatement.expression !is null)
        {
            write(' ');
            super.visit(returnStatement);
        }

        writeSemicolon();
    }

    // TODO
    override void visit(const ScopeGuardStatement scopeGuardStatement)
    {
        super.visit(scopeGuardStatement);
    }

    // TODO
    override void visit(const SharedStaticConstructor sharedStaticConstructor)
    {
        super.visit(sharedStaticConstructor);
    }

    // TODO
    override void visit(const SharedStaticDestructor sharedStaticDestructor)
    {
        super.visit(sharedStaticDestructor);
    }

    // TODO
    override void visit(const ShiftExpression shiftExpression)
    {
        tryVisit(shiftExpression.left);
        writef(" %s ", str(shiftExpression.operator));
        tryVisit(shiftExpression.right);
    }

    // TODO
    override void visit(const SingleImport singleImport)
    {
        if (singleImport.rename.type != tok!"")
        {
            visit(singleImport.rename);
            write(" = ");
        }

        visit(singleImport.identifierChain);
    }

    // TODO
    override void visit(const Index index)
    {
        super.visit(index);
    }

    // DONE
    override void visit(const SpecifiedFunctionBody specifiedFunctionBody)
    {
        tryVisit(specifiedFunctionBody.functionContracts);
        tryVisit(specifiedFunctionBody.blockStatement);
    }

    // TODO
    override void visit(const Statement statement)
    {
        super.visit(statement);
    }

    // TODO
    override void visit(const StatementNoCaseNoDefault statementNoCaseNoDefault)
    {
        super.visit(statementNoCaseNoDefault);
    }

    // TODO
    override void visit(const StaticAssertDeclaration staticAssertDeclaration)
    {
        super.visit(staticAssertDeclaration);
    }

    // TODO
    override void visit(const StaticAssertStatement staticAssertStatement)
    {
        write("static ");
        super.visit(staticAssertStatement);
        writeSemicolon();
    }

    // TODO
    override void visit(const StaticConstructor staticConstructor)
    {
        super.visit(staticConstructor);
    }

    // TODO
    override void visit(const StaticDestructor staticDestructor)
    {
        super.visit(staticDestructor);
    }

    // TODO
    override void visit(const StaticIfCondition staticIfCondition)
    {
        super.visit(staticIfCondition);
    }

    // DONE
    override void visit(const StorageClass storageClass)
    {
        super.visit(storageClass);
        write(' ');
    }

    // TODO
    override void visit(const StructBody structBody)
    {
        if (structBody.declarations.length > 0)
        {
            writeBraces(BraceKind.start);
            super.visit(structBody);
            writeBraces(BraceKind.end);
        }
        else
            writeBraces(BraceKind.empty);
    }

    // TODO
    override void visit(const StructDeclaration structDeclaration)
    {
        super.visit(structDeclaration);
    }

    // TODO
    override void visit(const StructInitializer structInitializer)
    {
        super.visit(structInitializer);
    }

    // TODO
    override void visit(const StructMemberInitializer structMemberInitializer)
    {
        super.visit(structMemberInitializer);
    }

    // TODO
    override void visit(const StructMemberInitializers structMemberInitializers)
    {
        super.visit(structMemberInitializers);
    }

    // TODO
    override void visit(const SwitchStatement switchStatement)
    {
        super.visit(switchStatement);
    }

    // TODO
    override void visit(const Symbol symbol)
    {
        super.visit(symbol);
    }

    // TODO
    override void visit(const SynchronizedStatement synchronizedStatement)
    {
        super.visit(synchronizedStatement);
    }

    // TODO
    override void visit(const TemplateAliasParameter templateAliasParameter)
    {
        super.visit(templateAliasParameter);
    }

    // TODO
    override void visit(const TemplateArgument templateArgument)
    {
        super.visit(templateArgument);
    }

    // TODO
    override void visit(const TemplateArgumentList templateArgumentList)
    {
        super.visit(templateArgumentList);
    }

    // TODO
    override void visit(const TemplateArguments templateArguments)
    {
        super.visit(templateArguments);
    }

    // TODO
    override void visit(const TemplateDeclaration templateDeclaration)
    {
        super.visit(templateDeclaration);
    }

    // TODO
    override void visit(const TemplateInstance templateInstance)
    {
        super.visit(templateInstance);
    }

    // TODO
    override void visit(const TemplateMixinExpression templateMixinExpression)
    {
        super.visit(templateMixinExpression);
    }

    // TODO
    override void visit(const TemplateParameter templateParameter)
    {
        super.visit(templateParameter);
    }

    // DONE
    override void visit(const TemplateParameterList templateParameterList)
    {
        writeList(templateParameterList.items);
    }

    // DONE
    override void visit(const TemplateParameters templateParameters)
    {
        write('(');
        visit(templateParameters.templateParameterList);
        write(')');
    }

    // TODO
    override void visit(const TemplateSingleArgument templateSingleArgument)
    {
        super.visit(templateSingleArgument);
    }

    // TODO
    override void visit(const TemplateThisParameter templateThisParameter)
    {
        super.visit(templateThisParameter);
    }

    // TODO
    override void visit(const TemplateTupleParameter templateTupleParameter)
    {
        super.visit(templateTupleParameter);
    }

    // TODO
    override void visit(const TemplateTypeParameter templateTypeParameter)
    {
        super.visit(templateTypeParameter);
    }

    // TODO
    override void visit(const TemplateValueParameter templateValueParameter)
    {
        super.visit(templateValueParameter);
    }

    // TODO
    override void visit(const TemplateValueParameterDefault templateValueParameterDefault)
    {
        super.visit(templateValueParameterDefault);
    }

    // TODO
    override void visit(const TernaryExpression ternaryExpression)
    {
        super.visit(ternaryExpression);
    }

    // TODO
    override void visit(const ThrowStatement throwStatement)
    {
        super.visit(throwStatement);
    }

    // TODO
    override void visit(const Token token)
    {
        import dls.tools.format.internal.util : tokenString;

        write(tokenString(token));
    }

    // TODO
    override void visit(const TraitsExpression traitsExpression)
    {
        super.visit(traitsExpression);
    }

    // TODO
    override void visit(const TryStatement tryStatement)
    {
        super.visit(tryStatement);
    }

    // TODO
    override void visit(const Type type)
    {
        foreach (typeCtor; type.typeConstructors)
            writef("%s ", str(typeCtor));

        super.visit(type);
    }

    // TODO
    override void visit(const TypeIdentifierPart typeIdentChain)
    {
        tryVisit(typeIdentChain.identifierOrTemplateInstance);

        if (typeIdentChain.typeIdentifierPart !is null)
        {
            write('.');
            visit(typeIdentChain.typeIdentifierPart);
        }

        tryVisit(typeIdentChain.indexer);
    }

    // TODO
    override void visit(const Type2 type2)
    {
        if (type2.typeConstructor != tok!"")
        {
            writef("%s(", str(type2.typeConstructor));
        }

    s:
        switch (type2.builtinType)
        {
            static foreach (T; builtinTypes)
                mixin(`case tok!"` ~ T ~ `": write("` ~ T ~ `"); break s;`);

        default:
            break;
        }

        super.visit(type2);

        if (type2.typeConstructor != tok!"")
            write(')');
    }

    // TODO
    override void visit(const TypeSpecialization typeSpecialization)
    {
        super.visit(typeSpecialization);
    }

    // TODO
    override void visit(const TypeSuffix typeSuffix)
    {
        super.visit(typeSuffix);
    }

    // TODO
    override void visit(const TypeidExpression typeidExpression)
    {
        super.visit(typeidExpression);
    }

    // TODO
    override void visit(const TypeofExpression typeofExpression)
    {
        super.visit(typeofExpression);
    }

    // TODO
    override void visit(const UnaryExpression unaryExpression)
    {
        super.visit(unaryExpression);
    }

    // TODO
    override void visit(const UnionDeclaration unionDeclaration)
    {
        super.visit(unionDeclaration);
    }

    // TODO
    override void visit(const Unittest unittest_)
    {
        super.visit(unittest_);
    }

    // DONE
    override void visit(const VariableDeclaration variableDeclaration)
    {
        if (variableDeclaration.autoDeclaration is null)
        {
            tryVisit(variableDeclaration.storageClasses);
            tryVisit(variableDeclaration.type);
            write(' ');
            writeList(variableDeclaration.declarators);
        }
        else
            visit(variableDeclaration.autoDeclaration);

        writeSemicolon();
    }

    // TODO
    override void visit(const Vector vector)
    {
        super.visit(vector);
    }

    // TODO
    override void visit(const VersionCondition versionCondition)
    {
        super.visit(versionCondition);
    }

    // TODO
    override void visit(const VersionSpecification versionSpecification)
    {
        super.visit(versionSpecification);
    }

    // TODO
    override void visit(const WhileStatement whileStatement)
    {
        super.visit(whileStatement);
    }

    // TODO
    override void visit(const WithStatement withStatement)
    {
        super.visit(withStatement);
    }

    // TODO
    override void visit(const XorExpression xorExpression)
    {
        super.visit(xorExpression);
    }

    private void tryVisit(T)(ref T field)
    {
        import std.traits : isArray;

        if (field !is null)
        {
            static if (isArray!T)
                foreach (item; field)
                    visit(item);
            else
                visit(field);
        }
    }

    private void beginTransaction()
    {
        _result.save();
        _lineLength.save();
        _tokenInfo.save();
        _result = new OutBuffer();
    }

    private void commitTransaction()
    {
        auto data = _result.data;
        _result.load();
        _result.write(data);
    }

    private void cancelTransaction()
    {
        _result.load();
        _lineLength.load();
        _tokenInfo.load();
    }

    private size_t indentLength()
    {
        import dls.tools.format.internal.config : IndentStyle;

        return _indentLevel * (_config.indentStyle == IndentStyle.space
                ? _config.indentSize : _config.tabWidth);
    }

    private bool canAddToCurrentLine(size_t length)
    {
        return _lineLength + length <= (indentLength * 4 > _config.softMaxLineLength
                ? _config.maxLineLength : _config.softMaxLineLength);
    }

    private void write(const char character)
    {
        _result.write(character);
        _lineLength += character == '\t' ? _config.tabWidth : 1;
    }

    private void write(const char[] text)
    {
        import std.algorithm : count;

        const numTabs = count(text, '\t');
        _result.write(text);
        _lineLength += text.length - numTabs + (numTabs * _config.tabWidth);
    }

    private void writef(Args...)(const char[] text, const Args args)
    {
        import std.format : format;

        write(format(text, args));
    }

    private void writeIndents()
    {
        import dls.tools.format.internal.config : IndentStyle;

        if (_inlineDepth > 0 || _lineLength > 0)
        {
            write(' ');
            return;
        }

        static char[] indents;
        indents.length = (_indentLevel + _tempIndentLevel) * (
                _config.indentStyle == IndentStyle.space ? _config.indentSize : 1);
        indents[] = _config.indentStyle;
        write(indents);
    }

    private void writeBraces(const BraceKind kind)
    {
        import dls.tools.format.internal.config : BraceStyle;

        final switch (kind)
        {
        case BraceKind.empty:
            write(" {}");
            break;

        case BraceKind.start:
            if (_config.braceStyle == BraceStyle.otbs)
                write(' ');
            else
            {
                writeNewLine();
                writeIndents();
            }

            write('{');
            ++_indentLevel;
            break;

        case BraceKind.end:
            --_indentLevel;
            writeIndents();
            write('}');
            break;
        }

        writeNewLine();

        if (kind != BraceKind.start)
        {
            if (_inlineDepth == 0 && _tokenInfo.emptyLines.current)
                writeNewLine();

            ++_tokenInfo.emptyLines.index;
        }
    }

    private void writeSemicolon(bool allowEmptyLine = true)
    {
        write(';');
        writeNewLine();
        _tempIndentLevel = 0;

        if (allowEmptyLine && _inlineDepth == 0 && _tokenInfo.emptyLines.current)
            writeNewLine();

        ++_tokenInfo.emptyLines.index;
    }

    private void writeNewLine()
    {
        if (_inlineDepth == 0)
        {
            write(_config.endOfLine);
            _lineLength = 0;
        }
    }

    private void writeList(T)(T[] list, bool startWithComma = false)
    {
        auto putComma = startWithComma;
        ++_tempIndentLevel;

        foreach (arg; list)
        {
            if (putComma)
            {
                write(',');
                beginTransaction();
                write(' ');
                visit(arg);

                if (canAddToCurrentLine(arg == list[$ - 1] ? 0 : 1))
                    commitTransaction();
                else
                {
                    cancelTransaction();
                    writeNewLine();
                    writeIndents();
                    visit(arg);
                }
            }
            else
            {
                putComma = true;
                visit(arg);
            }
        }

        --_tempIndentLevel;
    }

    private void writeCurrentStyle(bool start)
    {
        final switch (_styles.front)
        {
        case Style.newLine:
            if (!start)
            {
                writeNewLine();
                writeIndents();
            }
            break;

        case Style.spaceBefore:
            if (start)
                write(' ');
            break;

        case Style.spaceAfter:
            if (!start)
                write(' ');
            break;

        case Style.none:
            break;
        }
    }

    private void writeAttributes(const Attribute[] attributes)
    {
        import std.algorithm : filter;

        if (attributes is null)
            return;

        const(Attribute)[] firstAttributes;
        const(Attribute)[] otherAttributes;

        foreach (attr; attributes)
        {
            if (attr.atAttribute is null && attr.linkageAttribute is null)
                otherAttributes ~= attr;
            else
                firstAttributes ~= attr;
        }

        foreach (attr; firstAttributes)
        {
            visit(attr);
            writeNewLine();
            writeIndents();
        }

        foreach (attr; otherAttributes)
        {
            visit(attr);
            write(' ');
        }
    }

    private void writeEnumHeader(const string name, const Type type)
    {
        auto enumAndName = "enum";

        if (name !is null)
            enumAndName ~= ' ' ~ name;

        write(enumAndName);

        if (type !is null)
        {
            write(" : ");
            visit(type);
        }
    }

    private void writeEnumBody(T)(const T[] enumMembers)
    {
        if (enumMembers.length > 0)
        {
            beginTransaction();
            ++_inlineDepth;
            writeEnumMembers(enumMembers);
            --_inlineDepth;

            if (canAddToCurrentLine(0))
            {
                commitTransaction();
                writeNewLine();
            }
            else
            {
                cancelTransaction();
                writeEnumMembers(enumMembers);
            }
        }
        else
        {
            writeBraces(BraceKind.empty);
        }
    }

    private void writeEnumMembers(T)(const T[] enumMembers)
    {
        writeBraces(BraceKind.start);
        writeIndents();

        foreach (i, member; enumMembers)
        {
            visit(member);

            if (i + 1 < enumMembers.length)
            {
                write(',');
                writeNewLine();
                writeIndents();
            }
            else
                writeNewLine();
        }

        writeBraces(BraceKind.end);
    }

    private void writeEnumMember(T)(const T enumMember)
    {
        if (enumMember.type !is null)
        {
            visit(enumMember.type);
            write(' ');
        }

        visit(enumMember.name);

        if (enumMember.assignExpression !is null)
        {
            write(" = ");
            visit(enumMember.assignExpression);
        }
    }

    alias visit = ASTVisitor.visit;
}
