#include "rcl_lexer.hpp"

#include <cctype>

namespace rcl {

Lexer::Lexer(const std::string& input) : input_(input) {}

bool IsIdentifierStart(char c) {
  return std::isalpha(static_cast<unsigned char>(c)) || c == '_';
}

bool IsIdentifierChar(char c) {
  return std::isalnum(static_cast<unsigned char>(c)) || c == '_';
}

void SetError(Error& error, const std::string& message, std::size_t line, std::size_t column) {
  error.ok = false;
  error.message = message;
  error.line = line;
  error.column = column;
}

bool Lexer::Eof() const { return pos_ >= input_.size(); }
char Lexer::Cur() const { return Eof() ? '\0' : input_[pos_]; }
char Lexer::Peek() const { return pos_ + 1 < input_.size() ? input_[pos_ + 1] : '\0'; }

void Lexer::Advance() {
  if (Eof()) return;
  if (Cur() == '\n') {
    line_++;
    column_ = 1;
  } else {
    column_++;
  }
  pos_++;
}

void Lexer::Skip() {
  while (!Eof()) {
    if (Cur() == '#') {
      while (!Eof() && Cur() != '\n') Advance();
    } else if (Cur() == ' ' || Cur() == '\t' || Cur() == '\r' || Cur() == '\n') {
      Advance();
    } else {
      break;
    }
  }
}

bool Lexer::ReadIdentifier(Token& token) {
  const std::size_t start = pos_;
  token.line = line_;
  token.column = column_;
  while (!Eof() && IsIdentifierChar(Cur())) Advance();
  token.lexeme = input_.substr(start, pos_ - start);
  if (token.lexeme == "do") token.kind = TokenKind::Do;
  else if (token.lexeme == "end") token.kind = TokenKind::End;
  else token.kind = TokenKind::Identifier;
  return true;
}

bool Lexer::ReadNumber(Token& token) {
  const std::size_t start = pos_;
  token.line = line_;
  token.column = column_;
  if (Cur() == '-') Advance();
  while (!Eof() && std::isdigit(static_cast<unsigned char>(Cur()))) Advance();
  if (!Eof() && Cur() == '.') {
    Advance();
    if (!std::isdigit(static_cast<unsigned char>(Cur()))) return false;
    while (!Eof() && std::isdigit(static_cast<unsigned char>(Cur()))) Advance();
  }
  token.kind = TokenKind::Number;
  token.lexeme = input_.substr(start, pos_ - start);
  return true;
}

bool Lexer::ReadString(Token& token, Error& error) {
  const std::size_t line = line_, column = column_;
  token.line = line_;
  token.column = column_;
  token.kind = TokenKind::String;
  token.lexeme.clear();
  Advance();
  while (!Eof() && Cur() != '"') {
    char ch = Cur();
    if (ch == '\\') {
      Advance();
      if (Eof()) {
        SetError(error, "unterminated string", line, column);
        return false;
      }
      if (Cur() == '"') ch = '"';
      else if (Cur() == '\\') ch = '\\';
      else if (Cur() == 'n') ch = '\n';
      else if (Cur() == 't') ch = '\t';
      else {
        SetError(error, "invalid escape", line_, column_);
        return false;
      }
    }
    token.lexeme.push_back(ch);
    Advance();
  }
  if (Eof()) {
    SetError(error, "unterminated string", line, column);
    return false;
  }
  Advance();
  return true;
}

bool Lexer::Next(Token& token, Error& error) {
  Skip();
  token.lexeme.clear();
  token.line = line_;
  token.column = column_;
  if (Eof()) {
    token.kind = TokenKind::Eof;
    return true;
  }
  if (IsIdentifierStart(Cur())) return ReadIdentifier(token);
  if (Cur() == '-' || std::isdigit(static_cast<unsigned char>(Cur()))) return ReadNumber(token);
  if (Cur() == '"') return ReadString(token, error);
  if (Cur() == '\'') {
    SetError(error, "single-quoted string usage", line_, column_);
    return false;
  }
  token.lexeme.assign(1, Cur());
  if (Cur() == '=') token.kind = TokenKind::Equal;
  else if (Cur() == ',') token.kind = TokenKind::Comma;
  else if (Cur() == '.') token.kind = TokenKind::Dot;
  else if (Cur() == '[') token.kind = TokenKind::LBracket;
  else if (Cur() == ']') token.kind = TokenKind::RBracket;
  else {
    SetError(error, "unexpected character", line_, column_);
    return false;
  }
  Advance();
  return true;
}

}
