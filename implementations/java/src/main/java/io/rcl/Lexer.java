package io.rcl;

import java.util.ArrayList;
import java.util.List;

final class Lexer {
  static List<Token> lex(String src) {
    List<Token> out = new ArrayList<>();
    int i = 0, line = 1, col = 1, n = src.length();
    while (i < n) {
      char ch = src.charAt(i);
      if (ch == ' ' || ch == '\t' || ch == '\r') { i++; col++; continue; }
      if (ch == '\n') { i++; line++; col = 1; continue; }
      if (ch == '#') { while (i < n && src.charAt(i) != '\n') { i++; col++; } continue; }
      if (ch == '\'') throw err("single-quoted string usage", line, col);
      if (ch == '/' && i + 1 < n && src.charAt(i + 1) == '/') throw err("unexpected character", line, col);
      if (idStart(ch)) {
        int s = i, c0 = col;
        while (i < n && idPart(src.charAt(i))) { i++; col++; }
        String v = src.substring(s, i);
        out.add(new Token(v.equals("do") ? TokenKind.DO : v.equals("end") ? TokenKind.END : TokenKind.IDENT, v, line, c0));
        continue;
      }
      if (ch == '-' || Character.isDigit(ch)) {
        int s = i, c0 = col;
        if (ch == '-') {
          if (i + 1 >= n || !Character.isDigit(src.charAt(i + 1))) throw err("unexpected character", line, col);
          i++; col++;
        }
        while (i < n && Character.isDigit(src.charAt(i))) { i++; col++; }
        if (i < n && src.charAt(i) == '.') {
          if (i + 1 >= n || !Character.isDigit(src.charAt(i + 1))) throw err("unexpected character", line, col);
          i++; col++;
          while (i < n && Character.isDigit(src.charAt(i))) { i++; col++; }
        }
        out.add(new Token(TokenKind.NUMBER, src.substring(s, i), line, c0));
        continue;
      }
      if (ch == '"') {
        int c0 = col;
        StringBuilder sb = new StringBuilder();
        i++; col++;
        while (i < n && src.charAt(i) != '"') {
          char x = src.charAt(i);
          if (x == '\n') throw err("unterminated string", line, c0);
          if (x == '\\') {
            i++; col++;
            if (i >= n) throw err("unterminated string", line, c0);
            char e = src.charAt(i);
            if (e == '"') sb.append('"');
            else if (e == '\\') sb.append('\\');
            else if (e == 'n') sb.append('\n');
            else if (e == 't') sb.append('\t');
            else throw err("invalid escape", line, col);
            i++; col++;
            continue;
          }
          sb.append(x); i++; col++;
        }
        if (i >= n) throw err("unterminated string", line, c0);
        i++; col++;
        out.add(new Token(TokenKind.STRING, sb.toString(), line, c0));
        continue;
      }
      TokenKind k = switch (ch) {
        case '=' -> TokenKind.EQ;
        case ',' -> TokenKind.COMMA;
        case '.' -> TokenKind.DOT;
        case '[' -> TokenKind.LBR;
        case ']' -> TokenKind.RBR;
        default -> null;
      };
      if (k == null) throw err("unexpected character", line, col);
      out.add(new Token(k, String.valueOf(ch), line, col));
      i++; col++;
    }
    out.add(new Token(TokenKind.EOF, "", line, col));
    return out;
  }

  private static boolean idStart(char ch) { return Character.isLetter(ch) || ch == '_'; }
  private static boolean idPart(char ch) { return Character.isLetterOrDigit(ch) || ch == '_'; }
  static ParseError err(String msg, int line, int col) { return new ParseError(msg, line, col); }
}
