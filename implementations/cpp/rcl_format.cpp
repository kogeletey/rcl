#include "rcl.hpp"

#include <sstream>

namespace rcl {

namespace {

std::string Escape(const std::string& text) {
  std::string out = "\"";
  for (char ch : text) {
    if (ch == '"') out += "\\\"";
    else if (ch == '\\') out += "\\\\";
    else if (ch == '\n') out += "\\n";
    else if (ch == '\t') out += "\\t";
    else out += ch;
  }
  out += "\"";
  return out;
}

std::string FormatValue(const Value& value) {
  std::ostringstream out;
  if (value.kind == ValueKind::String) return Escape(value.string_value);
  if (value.kind == ValueKind::Number) {
    out << value.number_value;
    return out.str();
  }
  if (value.kind == ValueKind::Boolean) return value.bool_value ? "true" : "false";
  out << "[";
  for (std::size_t i = 0; i < value.array_value.size(); i++) {
    if (i > 0) out << ", ";
    out << FormatValue(value.array_value[i]);
  }
  out << "]";
  return out.str();
}

void FormatBlock(const Block& block, std::size_t indent, std::string& out) {
  const std::string pad(indent * 2, ' ');
  out += pad + block.name;
  if (block.has_argument) out += " " + Escape(block.argument);
  out += " do\n";
  for (const auto& st : block.statements) {
    if (st.kind == StatementKind::Property) {
      out += pad + "  " + st.property.key + " = " + FormatValue(st.property.value) + "\n";
    } else {
      FormatBlock(*st.block, indent + 1, out);
    }
  }
  out += pad + "end\n";
}

}

std::string format_document(const Document& doc) {
  std::string out;
  for (const auto* block : doc.blocks) FormatBlock(*block, 0, out);
  return out;
}

}
