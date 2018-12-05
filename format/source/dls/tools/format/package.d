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

module dls.tools.format;

public import dls.tools.format.internal.config;
import dparse.lexer : Token;
import dls.tools.format.internal.format_visitor : TokenInfo;

string format(const string sourceText, const FormatConfig config = FormatConfig())
{
    import dls.tools.format.internal.format_visitor : FormatVisitor;
    import dls.tools.format.internal.repair : repair;
    import dparse.lexer : LexerConfig, StringBehavior, StringCache,
        WhitespaceBehavior, byToken, getTokensForParser;
    import dparse.parser : parseModule;
    import dparse.rollback_allocator : RollbackAllocator;
    import std.array : array;
    import std.functional : toDelegate;

    auto lexerConfig = LexerConfig("", StringBehavior.source, WhitespaceBehavior.skip);
    auto stringCache = StringCache(StringCache.defaultBucketCount);
    const parserTokens = getTokensForParser(sourceText, lexerConfig, &stringCache);
    const inputTokens = byToken(sourceText, lexerConfig, &stringCache).array;
    RollbackAllocator ra;
    const mod = parseModule(parserTokens, "", &ra, toDelegate(&doNothing));
    auto visitor = new FormatVisitor(inputTokens, config, getTokenInfo(inputTokens));
    visitor.visit(mod);
    auto result = visitor.result.toString();
    return repair(sourceText, inputTokens, stringCache, result);
}

private TokenInfo getTokenInfo(const Token[] tokens)
{
    import dparse.lexer : tok;
    import std.algorithm : max;

    TokenInfo result;

    foreach (i, ref token; tokens[0 .. max(0, $ - 1)])
    {
        if (token.type == tok!";" || token.type == tok!"}")
            result.emptyLines ~= tokens[i + 1].line - token.line > 1;
    }

    result.emptyLines ~= false;
    return result;
}

private void doNothing(string, size_t, size_t, string, bool)
{
}
