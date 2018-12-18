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

module dls.tools.symbol_tool.internal.symbol_visitor;

import dparse.ast;

package class SymbolVisitor(SymbolType) : ASTVisitor
{
    import dls.protocol.definitions : Range;
    import dls.protocol.interfaces : DocumentSymbol, SymbolKind, SymbolInformation;
    import dls.util.uri : Uri;
    import dparse.lexer : Token;
    import std.array : Appender;
    import std.typecons : nullable;

    Appender!(SymbolType[]) result;
    private Uri _uri;
    private const string _upperQuery;
    private const bool _listLocalSymbols;

    static if (is(SymbolType == SymbolInformation))
    {
        private string _container;
    }
    else
    {
        private DocumentSymbol _container;
    }

    this(Uri uri, const string query, bool listLocalSymbols)
    {
        import std.uni : toUpper;

        _uri = uri;
        _upperQuery = toUpper(query);
        _listLocalSymbols = listLocalSymbols;
    }

    override void visit(const ClassDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.class_, true, dec.structBody is null ? 0
                : dec.structBody.endLocation);
    }

    override void visit(const StructDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.struct_, true, dec.structBody is null ? 0
                : dec.structBody.endLocation);
    }

    override void visit(const InterfaceDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.interface_, true, dec.structBody is null ? 0
                : dec.structBody.endLocation);
    }

    override void visit(const UnionDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.interface_, true, dec.structBody is null ? 0
                : dec.structBody.endLocation);
    }

    override void visit(const EnumDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.enum_, true, dec.enumBody is null ? 0 : dec
                .enumBody.endLocation);
    }

    override void visit(const EnumMember member)
    {
        visitSymbol(member, SymbolKind.enumMember, false);
    }

    override void visit(const AnonymousEnumMember member)
    {
        visitSymbol(member, SymbolKind.enumMember, false);
    }

    override void visit(const TemplateDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.function_, true, dec.endLocation);
    }

    override void visit(const FunctionDeclaration dec)
    {
        visitSymbol(dec, SymbolKind.function_, _listLocalSymbols, getFunctionEndLocation(dec));
    }

    override void visit(const Constructor dec)
    {
        visitFunction(dec, "this");
    }

    override void visit(const Destructor dec)
    {
        visitFunction(dec, "~this");
    }

    override void visit(const StaticConstructor dec)
    {
        visitFunction(dec, "static this");
    }

    override void visit(const StaticDestructor dec)
    {
        visitFunction(dec, "static ~this");
    }

    override void visit(const SharedStaticConstructor dec)
    {
        visitFunction(dec, "shared static this");
    }

    override void visit(const SharedStaticDestructor dec)
    {
        visitFunction(dec, "shared static ~this");
    }

    override void visit(const Parameter param)
    {
        if (_listLocalSymbols && param.name.text.length > 0)
        {
            visitSymbol(param, SymbolKind.variable, false);
        }
    }

    override void visit(const Invariant inv)
    {
        tryInsert("invariant", SymbolKind.function_, getRange(inv),
                inv.blockStatement is null ? 0 : inv.blockStatement.endLocation);
    }

    override void visit(const VariableDeclaration dec)
    {
        foreach (d; dec.declarators)
        {
            tryInsert(d.name.text.idup, SymbolKind.variable, getRange(d.name));
        }

        dec.accept(this);
    }

    override void visit(const AutoDeclaration dec)
    {
        foreach (part; dec.parts)
        {
            tryInsert(part.identifier.text.idup, SymbolKind.variable, getRange(part.identifier));
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
                tryInsert(id.text.idup, SymbolKind.variable, getRange(id));
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
        tryInsert(dec.identifier.text.idup, SymbolKind.variable, getRange(dec.identifier));
        dec.accept(this);
    }

    private size_t getFunctionEndLocation(A : ASTNode)(const A dec)
    {
        if (dec.functionBody !is null)
        {
            if (dec.functionBody.bodyStatement !is null)
            {
                return dec.functionBody.bodyStatement.blockStatement is null ? 0
                    : dec.functionBody.bodyStatement.blockStatement.endLocation;
            }

            return dec.functionBody.blockStatement is null ? 0
                : dec.functionBody.blockStatement.endLocation;
        }

        return 0;
    }

    private void visitSymbol(A : ASTNode)(const A dec, SymbolKind kind,
            bool accept, size_t endLocation = 0)
    {
        const name = dec.name.text.length > 0 ? dec.name.text.idup
            : "<anonymous " ~ __traits(identifier, A) ~ ">";
        tryInsert(name, kind, getRange(dec.name), endLocation);

        if (accept)
        {
            acceptSymbol(dec, dec.name.text.dup);
        }
    }

    private void visitFunction(A : ASTNode)(const A dec, const string name)
    {
        tryInsert(name, SymbolKind.function_, getRange(dec), getFunctionEndLocation(dec));

        if (_listLocalSymbols)
        {
            acceptSymbol(dec, name);
        }
    }

    private void acceptSymbol(A : ASTNode)(const A dec, string name)
    {
        auto oldContainer = _container;

        static if (is(SymbolType == SymbolInformation))
        {
            _container = name;
        }
        else
        {
            _container = (_container is null ? result.data : _container.children)[$ - 1];
        }

        dec.accept(this);
        _container = oldContainer;
    }

    private void tryInsert(const string name, SymbolKind kind, Range range, size_t endLocation = 0)
    {
        import dls.protocol.definitions : Location, Position;
        import dls.util.document : Document;
        import std.algorithm : canFind;
        import std.typecons : Nullable, nullable;
        import std.uni : toUpper;

        if (_upperQuery is null || toUpper(name).canFind(_upperQuery))
        {
            static if (is(SymbolType == SymbolInformation))
            {
                result ~= new SymbolInformation(name, kind, new Location(_uri,
                        range), _container.nullable);
            }
            else
            {
                auto fullRange = endLocation > 0 ? new Range(range.start,
                        Document.get(_uri).positionAtByte(endLocation)) : range;
                DocumentSymbol[] children;
                DocumentSymbol documentSymbol = new DocumentSymbol(name, Nullable!string(),
                        kind, Nullable!bool(), fullRange, range, children.nullable);
                if (_container is null)
                {
                    result ~= documentSymbol;
                }
                else
                {
                    _container.children ~= documentSymbol;
                }
            }
        }
    }

    private Range getRange(const Token t)
    {
        import dls.util.document : Document;

        return Document.get(_uri).wordRangeAtLineAndByte(t.line - 1, t.column - 1);
    }

    private Range getRange(T)(const T t)
    {
        import dls.util.document : Document;

        const document = Document.get(_uri);

        static if (__traits(hasMember, T, "index"))
        {
            return document.wordRangeAtByte(t.index);
        }
        else
        {
            return document.wordRangeAtByte(t.location);
        }
    }

    alias visit = ASTVisitor.visit;
}
