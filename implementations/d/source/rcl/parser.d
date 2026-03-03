module rcl.parser;

import std.string : split, indexOf;
import std.conv : to;
import rcl.ast;
import rcl.lexer;
import rcl.token;

struct Parser {
  Lexer lexer;
  Token cur;

  this(string input) { lexer = Lexer(input); cur = lexer.nextToken(); }

  void fail(string msg, Token t) { throw new Exception(msg ~ " at line " ~ t.line.to!string ~ ", column " ~ t.col.to!string); }

  void eat(TokenType t) {
    if (cur.typ != t) fail("Expected " ~ t.to!string ~ ", got " ~ cur.typ.to!string, cur);
    cur = lexer.nextToken();
  }

  Token peek(int n = 1) {
    auto p = lexer.pos;
    auto l = lexer.line;
    auto c = lexer.col;
    Token t;
    foreach (_; 0 .. n) t = lexer.nextToken();
    lexer.pos = p;
    lexer.line = l;
    lexer.col = c;
    return t;
  }

  static bool isPrefix(string[] a, string[] b) {
    if (a.length >= b.length) return false;
    foreach (i, x; a) if (b[i] != x) return false;
    return true;
  }

  void ensureKey(string key, string[] seen) {
    foreach (s; seen) {
      if (s == key) fail("Duplicate key '" ~ key ~ "'", cur);
      auto a = key.split(".");
      auto b = s.split(".");
      if (isPrefix(a, b) || isPrefix(b, a)) fail("Key conflict between '" ~ key ~ "' and '" ~ s ~ "'", cur);
    }
  }

  string parsePropertyKey() {
    auto key = cur.value;
    eat(TokenType.ident);
    while (cur.typ == TokenType.dot) {
      eat(TokenType.dot);
      if (cur.typ != TokenType.ident) fail("Expected identifier after dot", cur);
      key ~= "." ~ cur.value;
      eat(TokenType.ident);
    }
    return key;
  }

  AstNode parseValue() {
    if (cur.typ == TokenType.str) {
      auto v = cur.value;
      eat(TokenType.str);
      return AstNode(NodeKind.str, v, 0, false, false, null, null);
    }
    if (cur.typ == TokenType.num) {
      auto v = cur.value;
      eat(TokenType.num);
      return AstNode(NodeKind.num, "", v.to!double, false, indexOf(v, ".") >= 0, null, null);
    }
    if (cur.typ == TokenType.ident) {
      auto t = cur;
      auto v = t.value;
      eat(TokenType.ident);
      if (v == "true") return AstNode(NodeKind.boolv, "", 0, true, false, null, null);
      if (v == "false") return AstNode(NodeKind.boolv, "", 0, false, false, null, null);
      fail("Invalid bare value '" ~ v ~ "'", t);
    }
    if (cur.typ == TokenType.kwDo) {
      auto b = parseAnonymousBlock();
      auto ptr = new BlockNode;
      *ptr = b;
      return AstNode(NodeKind.block, "", 0, false, false, null, ptr);
    }
    if (cur.typ == TokenType.lbrack) return parseArray();
    fail("Unexpected token: " ~ cur.typ.to!string, cur);
    return AstNode(NodeKind.str, "", 0, false, false, null, null);
  }

  AstNode parseArray() {
    eat(TokenType.lbrack);
    AstNode[] items;
    if (cur.typ != TokenType.rbrack) {
      items ~= parseValue();
      while (cur.typ == TokenType.comma) {
        if (peek().typ == TokenType.rbrack) fail("Trailing comma in array", cur);
        eat(TokenType.comma);
        items ~= parseValue();
      }
    }
    if (cur.typ != TokenType.rbrack) fail("Missing ]", cur);
    eat(TokenType.rbrack);
    return AstNode(NodeKind.arr, "", 0, false, false, items, null);
  }

  void parseBlockBody(ref BlockNode b) {
    string[] seen;
    while (cur.typ != TokenType.kwEnd) {
      if (cur.typ == TokenType.eof) fail("missing 'end' for block", cur);
      if (cur.typ != TokenType.ident) fail("expected identifier, got " ~ cur.typ.to!string, cur);
      auto nxt = peek();
      if (nxt.typ == TokenType.kwDo && peek(2).typ == TokenType.lbrack) {
        auto key = cur.value;
        ensureKey(key, seen);
        seen ~= key;
        eat(TokenType.ident);
        eat(TokenType.kwDo);
        auto arr = parseArray();
        b.props[key] = arr;
        b.propOrder ~= key;
        eat(TokenType.kwEnd);
      } else if (nxt.typ == TokenType.kwDo || nxt.typ == TokenType.str) {
        auto child = parseBlock();
        if (child.hasArg) b.named ~= child;
        else b.blocks ~= child;
      } else if (nxt.typ == TokenType.eq || nxt.typ == TokenType.dot) {
        auto key = parsePropertyKey();
        ensureKey(key, seen);
        seen ~= key;
        eat(TokenType.eq);
        b.props[key] = parseValue();
        b.propOrder ~= key;
      } else fail("invalid statement after '" ~ cur.value ~ "'", cur);
    }
  }

  BlockNode parseBlock() {
    BlockNode b;
    b.name = cur.value;
    eat(TokenType.ident);
    if (cur.typ == TokenType.str) {
      b.hasArg = true;
      b.arg = cur.value;
      eat(TokenType.str);
    }
    eat(TokenType.kwDo);
    parseBlockBody(b);
    eat(TokenType.kwEnd);
    return b;
  }

  BlockNode parseAnonymousBlock() {
    BlockNode b;
    eat(TokenType.kwDo);
    parseBlockBody(b);
    eat(TokenType.kwEnd);
    return b;
  }

  Document parseDoc() {
    Document d;
    if (cur.typ == TokenType.kwDo) {
      eat(TokenType.kwDo);
      if (cur.typ != TokenType.lbrack) fail("Unexpected token after do", cur);
      d.hasRootValue = true;
      d.rootValue = parseArray();
      if (cur.typ != TokenType.eof) fail("Unexpected token after root array", cur);
      return d;
    }
    while (cur.typ != TokenType.eof) d.blocks ~= parseBlock();
    return d;
  }
}

Document parseDocument(string input) { return Parser(input).parseDoc(); }
