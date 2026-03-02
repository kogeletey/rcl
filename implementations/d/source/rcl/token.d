module rcl.token;

enum TokenType { eof, ident, str, num, kwDo, kwEnd, eq, comma, dot, lbrack, rbrack }

struct Token {
  TokenType typ;
  string value;
  int line;
  int col;
}
