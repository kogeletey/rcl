#include "rcl_lexer.hpp"

#include <algorithm>

namespace rcl {

namespace {

struct Parser {
  explicit Parser(const std::string& text) : lexer(text) {}
  Lexer lexer;
  Token current;
  Token peek;
  bool has_peek = false;
  Error* error = nullptr;
};

bool Next(Parser& p) {
  if (p.has_peek) {
    p.current = p.peek;
    p.has_peek = false;
    return true;
  }
  return p.lexer.Next(p.current, *p.error);
}

bool Ensure(Parser& p, TokenKind kind, const std::string& msg) {
  if (p.current.kind == kind) return true;
  SetError(*p.error, msg, p.current.line, p.current.column);
  return false;
}

bool IsPrefix(const std::string& a, const std::string& b) {
  return a.size() < b.size() && b.rfind(a + ".", 0) == 0;
}

bool KeyConflict(const std::vector<std::string>& keys, const std::string& key) {
  return std::any_of(keys.begin(), keys.end(), [&](const std::string& k) {
    return k == key || IsPrefix(k, key) || IsPrefix(key, k);
  });
}

bool ParseValue(Parser& p, Value& out);

bool ParseArray(Parser& p, Value& out) {
  out.kind = ValueKind::Array;
  if (!Next(p)) return false;
  if (p.current.kind == TokenKind::RBracket) return Next(p);
  while (true) {
    Value item;
    if (!ParseValue(p, item)) return false;
    out.array_value.push_back(item);
    if (p.current.kind == TokenKind::Comma) {
      if (!Next(p)) return false;
      if (p.current.kind == TokenKind::RBracket) {
        SetError(*p.error, "trailing comma in array", p.current.line, p.current.column);
        return false;
      }
      continue;
    }
    if (p.current.kind == TokenKind::RBracket) return Next(p);
    SetError(*p.error, "missing ]", p.current.line, p.current.column);
    return false;
  }
}

bool ParseValue(Parser& p, Value& out) {
  if (p.current.kind == TokenKind::String) {
    out.kind = ValueKind::String;
    out.string_value = p.current.lexeme;
    return Next(p);
  }
  if (p.current.kind == TokenKind::Number) {
    out.kind = ValueKind::Number;
    out.number_value = std::stod(p.current.lexeme);
    return Next(p);
  }
  if (p.current.kind == TokenKind::Identifier) {
    if (p.current.lexeme == "true" || p.current.lexeme == "false") {
      out.kind = ValueKind::Boolean;
      out.bool_value = p.current.lexeme == "true";
      return Next(p);
    }
    SetError(*p.error, "invalid bare identifier value", p.current.line, p.current.column);
    return false;
  }
  if (p.current.kind == TokenKind::LBracket) return ParseArray(p, out);
  SetError(*p.error, "unexpected token", p.current.line, p.current.column);
  return false;
}

bool ParseKey(Parser& p, std::string& key) {
  key = p.current.lexeme;
  if (!Next(p)) return false;
  while (p.current.kind == TokenKind::Dot) {
    if (!Next(p) || !Ensure(p, TokenKind::Identifier, "unexpected token")) return false;
    key += "." + p.current.lexeme;
    if (!Next(p)) return false;
  }
  return true;
}

bool ParseBlock(Parser& p, Block*& block) {
  block = new Block;
  std::vector<std::string> keys;
  block->name = p.current.lexeme;
  if (!Next(p)) return false;
  if (p.current.kind == TokenKind::String) {
    block->argument = p.current.lexeme;
    block->has_argument = true;
    if (!Next(p)) return false;
  }
  if (!Ensure(p, TokenKind::Do, "unexpected token") || !Next(p)) return false;
  while (p.current.kind != TokenKind::End) {
    if (p.current.kind == TokenKind::Eof) {
      SetError(*p.error, "missing end", p.current.line, p.current.column);
      return false;
    }
    if (!Ensure(p, TokenKind::Identifier, "unexpected token")) return false;
    if (!p.has_peek) {
      if (!p.lexer.Next(p.peek, *p.error)) return false;
      p.has_peek = true;
    }
    if (p.peek.kind == TokenKind::Equal || p.peek.kind == TokenKind::Dot) {
      Statement st;
      std::string key;
      st.kind = StatementKind::Property;
      if (!ParseKey(p, key)) return false;
      if (KeyConflict(keys, key)) {
        SetError(*p.error, "duplicate key or key-path prefix conflict", p.current.line, p.current.column);
        return false;
      }
      keys.push_back(key);
      st.property.key = key;
      if (!Ensure(p, TokenKind::Equal, "unexpected token") || !Next(p)) return false;
      if (!ParseValue(p, st.property.value)) return false;
      block->statements.push_back(st);
    } else if (p.peek.kind == TokenKind::Do || p.peek.kind == TokenKind::String) {
      Statement st;
      st.kind = StatementKind::Block;
      if (!ParseBlock(p, st.block)) return false;
      block->statements.push_back(st);
    } else {
      SetError(*p.error, "unexpected token", p.current.line, p.current.column);
      return false;
    }
  }
  return Next(p);
}

}

Document* parse(const std::string& text, Error& error) {
  auto* doc = new Document;
  Parser parser(text);
  error = Error{};
  parser.error = &error;
  if (!Next(parser)) {
    delete doc;
    return nullptr;
  }
  while (parser.current.kind != TokenKind::Eof) {
    Block* block = nullptr;
    if (!ParseBlock(parser, block)) {
      free_document(doc);
      return nullptr;
    }
    doc->blocks.push_back(block);
  }
  return doc;
}

}
