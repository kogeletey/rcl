#ifndef RCL_CPP_LEXER_HPP
#define RCL_CPP_LEXER_HPP

#include "rcl.hpp"

namespace rcl {

enum class TokenKind {
  Eof,
  Identifier,
  String,
  Number,
  Do,
  End,
  Equal,
  Comma,
  Dot,
  LBracket,
  RBracket
};

struct Token {
  TokenKind kind = TokenKind::Eof;
  std::string lexeme;
  std::size_t line = 1;
  std::size_t column = 1;
};

class Lexer {
 public:
  explicit Lexer(const std::string& input);
  bool Next(Token& token, Error& error);

 private:
  const std::string& input_;
  std::size_t pos_ = 0;
  std::size_t line_ = 1;
  std::size_t column_ = 1;

  bool Eof() const;
  char Cur() const;
  char Peek() const;
  void Advance();
  void Skip();
  bool ReadIdentifier(Token& token);
  bool ReadNumber(Token& token);
  bool ReadString(Token& token, Error& error);
};

bool IsIdentifierStart(char c);
bool IsIdentifierChar(char c);
void SetError(Error& error, const std::string& message, std::size_t line, std::size_t column);

}

#endif
