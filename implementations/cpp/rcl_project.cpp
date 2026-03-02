#include "rcl_project.hpp"

namespace rcl {

namespace {

Obj FromValue(const Value& value) {
  Obj out;
  if (value.kind == ValueKind::String) {
    out.kind = ObjKind::String;
    out.string_value = value.string_value;
  } else if (value.kind == ValueKind::Number) {
    out.kind = ObjKind::Number;
    out.number_value = value.number_value;
  } else if (value.kind == ValueKind::Boolean) {
    out.kind = ObjKind::Boolean;
    out.bool_value = value.bool_value;
  } else {
    out.kind = ObjKind::Array;
    for (const auto& item : value.array_value) out.array_value.push_back(FromValue(item));
  }
  return out;
}

void InsertPath(Obj& root, const std::string& path, Obj value) {
  const auto dot = path.find('.');
  if (dot == std::string::npos) {
    root.object_value[path] = std::move(value);
    return;
  }
  const std::string head = path.substr(0, dot);
  Obj& next = root.object_value[head];
  if (next.kind != ObjKind::Object) {
    next.kind = ObjKind::Object;
    next.object_value.clear();
  }
  InsertPath(next, path.substr(dot + 1), std::move(value));
}

void MergeObject(Obj& target, const Obj& source) {
  for (const auto& it : source.object_value) target.object_value[it.first] = it.second;
}

Obj ProjectBlock(const Block& block) {
  Obj out;
  out.kind = ObjKind::Object;
  for (const auto& st : block.statements) {
    if (st.kind == StatementKind::Property) {
      InsertPath(out, st.property.key, FromValue(st.property.value));
      continue;
    }
    Obj child = ProjectBlock(*st.block);
    if (!st.block->has_argument) {
      Obj& at = out.object_value[st.block->name];
      if (at.kind == ObjKind::Object) MergeObject(at, child);
      else at = child;
    } else {
      Obj& base = out.object_value[named_base(st.block->name)];
      base.kind = ObjKind::Object;
      base.object_value[st.block->argument] = child;
    }
  }
  return out;
}

}

std::string named_base(const std::string& name) {
  if (!name.empty() && name.back() == 's') return name;
  return name + "s";
}

Obj project(const Document& doc) {
  Obj root;
  root.kind = ObjKind::Object;
  for (const auto* block : doc.blocks) {
    Obj child = ProjectBlock(*block);
    if (!block->has_argument) root.object_value[block->name] = child;
    else {
      Obj& base = root.object_value[named_base(block->name)];
      base.kind = ObjKind::Object;
      base.object_value[block->argument] = child;
    }
  }
  return root;
}

}
