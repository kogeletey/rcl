#include "rcl_project.hpp"

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

std::string Scalar(const Obj& value) {
  std::ostringstream out;
  if (value.kind == ObjKind::String) return Escape(value.string_value);
  if (value.kind == ObjKind::Number) {
    out << value.number_value;
    return out.str();
  }
  if (value.kind == ObjKind::Boolean) return value.bool_value ? "true" : "false";
  out << "[";
  for (std::size_t i = 0; i < value.array_value.size(); i++) {
    if (i > 0) out << ", ";
    out << Scalar(value.array_value[i]);
  }
  out << "]";
  return out.str();
}

void Json(const Obj& value, std::string& out) {
  if (value.kind != ObjKind::Object) {
    out += Scalar(value);
    return;
  }
  out += "{";
  bool first = true;
  for (const auto& it : value.object_value) {
    if (!first) out += ",";
    first = false;
    out += Escape(it.first) + ":";
    Json(it.second, out);
  }
  out += "}";
}

void Yaml(const Obj& obj, std::size_t indent, std::string& out) {
  for (const auto& it : obj.object_value) {
    out += std::string(indent * 2, ' ') + it.first + ":";
    if (it.second.kind == ObjKind::Object) {
      out += "\n";
      Yaml(it.second, indent + 1, out);
    } else {
      out += " " + Scalar(it.second) + "\n";
    }
  }
}

void Hcl(const Obj& obj, std::size_t indent, std::string& out) {
  for (const auto& it : obj.object_value) {
    out += std::string(indent * 2, ' ') + it.first;
    if (it.second.kind == ObjKind::Object) {
      out += " {\n";
      Hcl(it.second, indent + 1, out);
      out += std::string(indent * 2, ' ') + "}\n";
    } else {
      out += " = " + Scalar(it.second) + "\n";
    }
  }
}

void Toml(const Obj& obj, const std::string& prefix, std::string& out) {
  if (!prefix.empty()) out += "[" + prefix + "]\n";
  for (const auto& it : obj.object_value) if (it.second.kind != ObjKind::Object) out += it.first + " = " + Scalar(it.second) + "\n";
  for (const auto& it : obj.object_value) {
    if (it.second.kind != ObjKind::Object) continue;
    out += "\n";
    const std::string next = prefix.empty() ? it.first : prefix + "." + it.first;
    Toml(it.second, next, out);
  }
}

}

std::string to_object_json(const Document& doc) {
  std::string out;
  Json(project(doc), out);
  return out;
}

std::string to_yaml(const Document& doc) {
  std::string out;
  Yaml(project(doc), 0, out);
  return out;
}

std::string to_toml(const Document& doc) {
  std::string out;
  Toml(project(doc), "", out);
  return out;
}

std::string to_hcl(const Document& doc) {
  std::string out;
  Hcl(project(doc), 0, out);
  return out;
}

}
