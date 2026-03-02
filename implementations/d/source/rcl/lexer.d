module rcl.lexer;

import rcl.token;

struct Lexer {
  string input;
  size_t pos;
  int line = 1;
  int col = 1;

  this(string s) { input = s; }

  char peek(size_t off = 0) const {
    auto i = pos + off;
    return i < input.length ? input[i] : '\0';
  }

  void advance() {
    auto ch = peek();
    if (ch == '\n') { line++; col = 1; }
    else col++;
    pos++;
  }

  void fail(string msg, int l, int c) { throw new Exception(msg ~ " at line " ~ l.to!string ~ ", column " ~ c.to!string); }

  void skipWsComments() {
    while (pos < input.length) {
      auto ch = peek();
      if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') advance();
      else if (ch == '#') while (pos < input.length && peek() != '\n') advance();
      else break;
    }
  }

  Token readString(int l, int c) {
    advance();
    string out;
    while (pos < input.length && peek() != '"') {
      auto ch = peek();
      if (ch == '\\') {
        advance();
        if (pos >= input.length) fail("Unterminated escape", l, c);
        auto esc = peek();
        if (esc == '"') out ~= '"';
        else if (esc == 'n') out ~= '\n';
        else if (esc == 't') out ~= '\t';
        else if (esc == '\\') out ~= '\\';
        else fail("Invalid escape sequence", line, col);
        advance();
      } else { out ~= ch; advance(); }
    }
    if (pos >= input.length) fail("Unterminated string", l, c);
    advance();
    return Token(TokenType.str, out, l, c);
  }

  Token readNumber(int l, int c) {
    string out;
    if (peek() == '-') { out ~= '-'; advance(); }
    while (peek() >= '0' && peek() <= '9') { out ~= peek(); advance(); }
    if (peek() == '.' && peek(1) >= '0' && peek(1) <= '9') {
      out ~= '.'; advance();
      while (peek() >= '0' && peek() <= '9') { out ~= peek(); advance(); }
    }
    return Token(TokenType.num, out, l, c);
  }

  Token readIdent(int l, int c) {
    string out;
    while ((peek() >= 'a' && peek() <= 'z') || (peek() >= 'A' && peek() <= 'Z') || (peek() >= '0' && peek() <= '9') || peek() == '_') {
      out ~= peek(); advance();
    }
    if (out == "do") return Token(TokenType.kwDo, out, l, c);
    if (out == "end") return Token(TokenType.kwEnd, out, l, c);
    return Token(TokenType.ident, out, l, c);
  }

  Token nextToken() {
    skipWsComments();
    if (pos >= input.length) return Token(TokenType.eof, "", line, col);
    auto ch = peek(); auto l = line; auto c = col;
    if (ch == '=') { advance(); return Token(TokenType.eq, "=", l, c); }
    if (ch == ',') { advance(); return Token(TokenType.comma, ",", l, c); }
    if (ch == '.') { advance(); return Token(TokenType.dot, ".", l, c); }
    if (ch == '[') { advance(); return Token(TokenType.lbrack, "[", l, c); }
    if (ch == ']') { advance(); return Token(TokenType.rbrack, "]", l, c); }
    if (ch == '"') return readString(l, c);
    if (ch == '\'') fail("single-quoted string usage", l, c);
    if (ch == '/' && peek(1) == '/') fail("unexpected character '/'", l, c);
    if ((ch >= '0' && ch <= '9') || (ch == '-' && peek(1) >= '0' && peek(1) <= '9')) return readNumber(l, c);
    if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_') return readIdent(l, c);
    fail("unexpected character '" ~ ch ~ "'", l, c);
    return Token(TokenType.eof, "", l, c);
  }
}

import std.conv : to;
