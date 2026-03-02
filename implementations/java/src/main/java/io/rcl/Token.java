package io.rcl;

enum TokenKind {
  EOF, IDENT, STRING, NUMBER, DO, END, EQ, COMMA, DOT, LBR, RBR
}

final class Token {
  final TokenKind kind;
  final String text;
  final int line;
  final int col;

  Token(TokenKind k, String t, int l, int c) {
    kind = k;
    text = t;
    line = l;
    col = c;
  }
}
