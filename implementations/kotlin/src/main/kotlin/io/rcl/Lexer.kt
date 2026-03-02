package io.rcl

enum class TokenType { Identifier, String, Number, Equal, Comma, Dot, Do, End, LBracket, RBracket, EOF }
data class Token(val type: TokenType, val value: String, val line: Int, val column: Int)

data class LexerState(val pos: Int, val line: Int, val column: Int)

class Lexer(private val input: String) {
  private var pos = 0
  private var line = 1
  private var column = 1

  fun snapshot() = LexerState(pos, line, column)
  fun restore(s: LexerState) { pos = s.pos; line = s.line; column = s.column }

  fun nextToken(): Token {
    skip()
    if (eof()) return Token(TokenType.EOF, "", line, column)
    val line0 = line
    val col0 = column
    val ch = cur()
    return when {
      ch == '=' -> one(TokenType.Equal, "=", line0, col0)
      ch == ',' -> one(TokenType.Comma, ",", line0, col0)
      ch == '.' -> one(TokenType.Dot, ".", line0, col0)
      ch == '[' -> one(TokenType.LBracket, "[", line0, col0)
      ch == ']' -> one(TokenType.RBracket, "]", line0, col0)
      ch == '"' -> readString(line0, col0)
      ch.isDigit() || (ch == '-' && peek().isDigit()) -> readNumber(line0, col0)
      ch.isLetter() || ch == '_' -> readIdentifier(line0, col0)
      else -> throw ParseError("unexpected character", line0, col0)
    }
  }

  private fun readString(line0: Int, col0: Int): Token {
    adv()
    val out = StringBuilder()
    while (!eof() && cur() != '"') {
      if (cur() == '\\') {
        adv()
        if (eof()) throw ParseError("unterminated escape", line0, col0)
        out.append(
          when (cur()) {
            '"' -> '"'; 'n' -> '\n'; 't' -> '\t'; '\\' -> '\\'
            else -> throw ParseError("invalid escape", line, column)
          }
        )
        adv()
      } else { out.append(cur()); adv() }
    }
    if (eof()) throw ParseError("unterminated string", line0, col0)
    adv()
    return Token(TokenType.String, out.toString(), line0, col0)
  }

  private fun readNumber(line0: Int, col0: Int): Token {
    val out = StringBuilder()
    if (cur() == '-') { out.append('-'); adv() }
    while (!eof() && cur().isDigit()) { out.append(cur()); adv() }
    if (!eof() && cur() == '.' && peek().isDigit()) {
      out.append('.'); adv(); while (!eof() && cur().isDigit()) { out.append(cur()); adv() }
    }
    return Token(TokenType.Number, out.toString(), line0, col0)
  }

  private fun readIdentifier(line0: Int, col0: Int): Token {
    val out = StringBuilder()
    while (!eof() && (cur().isLetterOrDigit() || cur() == '_')) { out.append(cur()); adv() }
    val value = out.toString()
    val type = when (value) { "do" -> TokenType.Do; "end" -> TokenType.End; else -> TokenType.Identifier }
    return Token(type, value, line0, col0)
  }

  private fun skip() {
    while (!eof()) {
      when {
        cur().isWhitespace() -> adv()
        cur() == '#' -> while (!eof() && cur() != '\n') adv()
        else -> return
      }
    }
  }

  private fun one(type: TokenType, value: String, line0: Int, col0: Int): Token { adv(); return Token(type, value, line0, col0) }
  private fun adv() { if (eof()) return; if (cur() == '\n') { line++; column = 1 } else column++; pos++ }
  private fun cur() = input[pos]
  private fun peek() = input.getOrElse(pos + 1) { '\u0000' }
  private fun eof() = pos >= input.length
}
