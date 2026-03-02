package io.rcl;

import java.util.ArrayList;
import java.util.List;

final class Parser {
  private final List<Token> t;
  private int p = 0;

  Parser(String src) { t = Lexer.lex(src); }

  DocumentNode parse() {
    DocumentNode doc = new DocumentNode();
    while (!is(TokenKind.EOF)) doc.blocks.add(parseBlock());
    return doc;
  }

  private BlockNode parseBlock() {
    Token n = eat(TokenKind.IDENT, "unexpected token");
    String arg = null;
    if (is(TokenKind.STRING)) arg = eat(TokenKind.STRING, "unexpected token").text;
    eat(TokenKind.DO, "unexpected token");
    BlockNode b = new BlockNode(n.text, arg);
    List<String> seen = new ArrayList<>();
    while (!is(TokenKind.END)) {
      if (is(TokenKind.EOF)) throw err("missing end");
      Token cur = eat(TokenKind.IDENT, "unexpected token");
      Token nxt = peek();
      if (nxt.kind == TokenKind.EQ || nxt.kind == TokenKind.DOT) {
        String key = parseKey(cur.text);
        validateKey(key, seen, cur);
        eat(TokenKind.EQ, "unexpected token");
        AstNode v = parseValue();
        b.properties.put(key, v);
        b.propertyOrder.add(key);
      } else if (nxt.kind == TokenKind.DO || nxt.kind == TokenKind.STRING) {
        p--;
        BlockNode c = parseBlock();
        if (c.argument == null) b.blocks.add(c); else b.namedBlocks.add(c);
      } else throw err("unexpected token");
    }
    eat(TokenKind.END, "unexpected token");
    return b;
  }

  private String parseKey(String first) {
    String key = first;
    while (is(TokenKind.DOT)) {
      eat(TokenKind.DOT, "unexpected token");
      key += "." + eat(TokenKind.IDENT, "unexpected token").text;
    }
    return key;
  }

  private AstNode parseValue() {
    if (is(TokenKind.STRING)) return new StringNode(eat(TokenKind.STRING, "unexpected token").text);
    if (is(TokenKind.NUMBER)) return new NumberNode(Double.parseDouble(eat(TokenKind.NUMBER, "unexpected token").text));
    if (is(TokenKind.IDENT)) {
      String v = eat(TokenKind.IDENT, "unexpected token").text;
      if (v.equals("true") || v.equals("false")) return new BooleanNode(v.equals("true"));
      throw err("invalid bare identifier value");
    }
    if (is(TokenKind.LBR)) return parseArray();
    throw err("unexpected token");
  }

  private AstNode parseArray() {
    eat(TokenKind.LBR, "unexpected token");
    ArrayNode arr = new ArrayNode();
    if (is(TokenKind.RBR)) { eat(TokenKind.RBR, "unexpected token"); return arr; }
    arr.elements.add(parseValue());
    while (is(TokenKind.COMMA)) {
      eat(TokenKind.COMMA, "unexpected token");
      if (is(TokenKind.RBR)) throw err("trailing comma in array");
      arr.elements.add(parseValue());
    }
    if (!is(TokenKind.RBR)) throw err("missing ]");
    eat(TokenKind.RBR, "unexpected token");
    return arr;
  }

  private void validateKey(String key, List<String> seen, Token t0) {
    for (String ex : seen) {
      if (ex.equals(key)) throw new ParseError("duplicate key", t0.line, t0.col);
      if (isPrefix(ex, key) || isPrefix(key, ex)) throw new ParseError("key-path prefix conflict", t0.line, t0.col);
    }
    seen.add(key);
  }

  private boolean isPrefix(String a, String b) { return a.length() < b.length() && b.startsWith(a + "."); }
  private boolean is(TokenKind k) { return t.get(p).kind == k; }
  private Token peek() { return t.get(Math.min(p, t.size() - 1)); }
  private Token eat(TokenKind k, String msg) { if (!is(k)) throw err(msg); return t.get(p++); }
  private ParseError err(String msg) { Token x = t.get(Math.min(p, t.size() - 1)); return new ParseError(msg, x.line, x.col); }
}

final class ParseError extends RuntimeException {
  final int line;
  final int column;
  ParseError(String m, int l, int c) { super("line " + l + ", column " + c + ": " + m); line = l; column = c; }
}
