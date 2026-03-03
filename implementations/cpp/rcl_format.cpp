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

std::string FormatInlineBlock(const Block& block);

std::string FormatValue(const Value& value) {
  std::ostringstream out;
  if (value.kind == ValueKind::String) return Escape(value.string_value);
  if (value.kind == ValueKind::Number) {
    out << value.number_value;
    return out.str();
  }
  if (value.kind == ValueKind::Boolean) return value.bool_value ? "true" : "false";
  if (value.kind == ValueKind::Block) return FormatInlineBlock(*value.block_value);
  out << "[";
  for (std::size_t i = 0; i < value.array_value.size(); i++) {
    if (i > 0) out << ", ";
    out << FormatValue(value.array_value[i]);
  }
  out << "]";
  return out.str();
}

std::string FormatInlineBlock(const Block& block) {
  std::string out = "do";
  for (const auto& st : block.statements) {
    out += " ";
    if (st.kind == StatementKind::Property) {
      out += st.property.key;
      if (st.property.value.kind == ValueKind::Array) out += " do " + FormatValue(st.property.value) + " end";
      else out += " = " + FormatValue(st.property.value);
    } else {
      out += st.block->name;
      if (st.block->has_argument) out += " " + Escape(st.block->argument);
      out += " " + FormatInlineBlock(*st.block);
    }
  }
  out += " end";
  return out;
}

void FormatBlock(const Block& block, std::size_t indent, std::string& out) {
  const std::string pad(indent * 2, ' ');
  out += pad + block.name;
  if (block.has_argument) out += " " + Escape(block.argument);
  out += " do\n";
  for (const auto& st : block.statements) {
    if (st.kind == StatementKind::Property) {
      if (st.property.value.kind == ValueKind::Array) out += pad + "  " + st.property.key + " do " + FormatValue(st.property.value) + " end\n";
      else out += pad + "  " + st.property.key + " = " + FormatValue(st.property.value) + "\n";
    } else {
      FormatBlock(*st.block, indent + 1, out);
    }
  }
  out += pad + "end\n";
}

}

std::string format_document(const Document& doc) {
  if (doc.has_root_value) return "do " + FormatValue(doc.root_value);
  std::string out;
  for (const auto* block : doc.blocks) FormatBlock(*block, 0, out);
  return out;
}

}
