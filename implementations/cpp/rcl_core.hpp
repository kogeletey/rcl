#ifndef RCL_CPP_CORE_HPP
#define RCL_CPP_CORE_HPP

#include <cstddef>
#include <memory>
#include <string>
#include <vector>

namespace rcl {

enum class ValueKind { String, Number, Boolean, Array, Block };

struct Block;

struct Value {
  ValueKind kind = ValueKind::String;
  std::string string_value;
  double number_value = 0.0;
  bool bool_value = false;
  std::vector<Value> array_value;
  std::shared_ptr<Block> block_value;
};

struct Property {
  std::string key;
  Value value;
};

enum class StatementKind { Property, Block };

struct Statement {
  StatementKind kind = StatementKind::Property;
  Property property;
  Block* block = nullptr;
};

struct Block {
  std::string name;
  std::string argument;
  bool has_argument = false;
  std::vector<Statement> statements;
};

struct Document {
  std::vector<Block*> blocks;
  bool has_root_value = false;
  Value root_value;
};

struct Error {
  bool ok = true;
  std::string message;
  std::size_t line = 0;
  std::size_t column = 0;
};

Document* parse(const std::string& text, Error& error);
void free_document(Document* doc);

std::string to_object_json(const Document& doc);

}  // namespace rcl

#endif
