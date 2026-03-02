module rcl.converters;

import std.algorithm : sort;
import std.array : array, join;
import std.conv : to;
import std.json;
import rcl.ast;
import std.string : split, replace;

string namedBase(string n) { return n.length > 0 && n[$ - 1] == 's' ? n : n ~ "s"; }
string indentPad(int indent) {
  string pad;
  foreach (_; 0 .. indent) pad ~= "  ";
  return pad;
}

JSONValue nodeToVal(AstNode n) {
  final switch (n.kind) {
    case NodeKind.str: return JSONValue(n.sval);
    case NodeKind.num: return n.isInt ? JSONValue(cast(long)n.nval) : JSONValue(n.nval);
    case NodeKind.boolv: return JSONValue(n.bval);
    case NodeKind.arr:
      JSONValue[] items; foreach (e; n.elems) items ~= nodeToVal(e); return JSONValue(items);
  }
}

void insertPath(ref JSONValue obj, string key, JSONValue v) {
  auto parts = key.split(".");
  if (parts.length == 1) {
    if (parts[0] in obj.object) throw new Exception("duplicate key '" ~ key ~ "'");
    obj.object[parts[0]] = v;
    return;
  }
  auto head = parts[0];
  auto tail = parts[1 .. $].join(".");
  if (!(head in obj.object)) obj.object[head] = JSONValue(string[string].init);
  if (obj.object[head].type != JSON_TYPE.OBJECT) throw new Exception("key conflict at '" ~ head ~ "'");
  auto child = obj.object[head];
  insertPath(child, tail, v);
  obj.object[head] = child;
}

JSONValue blockToObject(BlockNode b) {
  JSONValue obj = JSONValue(string[string].init);
  foreach (k; b.propOrder) insertPath(obj, k, nodeToVal(b.props[k]));
  foreach (c; b.blocks) {
    auto child = blockToObject(c);
    if (auto ex = c.name in obj.object) {
      if ((*ex).type == JSON_TYPE.OBJECT) foreach (k, v; child.object) (*ex).object[k] = v;
      else obj.object[c.name] = child;
    } else obj.object[c.name] = child;
  }
  foreach (c; b.named) {
    auto base = namedBase(c.name);
    if (!(base in obj.object)) obj.object[base] = JSONValue(string[string].init);
    obj.object[base].object[c.arg] = blockToObject(c);
  }
  return obj;
}

JSONValue toObjectDocument(Document d) {
  JSONValue obj = JSONValue(string[string].init);
  foreach (b; d.blocks) {
    if (b.hasArg) {
      JSONValue m = JSONValue(string[string].init);
      m.object[b.arg] = blockToObject(b);
      obj.object[namedBase(b.name)] = m;
    } else obj.object[b.name] = blockToObject(b);
  }
  return obj;
}

string esc(string s) { return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t"); }
string scalar(JSONValue v) {
  switch (v.type) {
    case JSON_TYPE.STRING: return "\"" ~ esc(v.str) ~ "\"";
    case JSON_TYPE.INTEGER: return v.integer.to!string;
    case JSON_TYPE.FLOAT: return v.floating.to!string;
    case JSON_TYPE.TRUE: return "true";
    case JSON_TYPE.FALSE: return "false";
    case JSON_TYPE.ARRAY:
      string[] parts;
      foreach (x; v.array) parts ~= scalar(x);
      return "[" ~ parts.join(", ") ~ "]";
    case JSON_TYPE.OBJECT: return "{}";
    case JSON_TYPE.NULL: return "null";
    default: return "null";
  }
}

string emitYAML(JSONValue v, int indent=0) {
  auto pad = indentPad(indent);
  if (v.type == JSON_TYPE.ARRAY) {
    string[] lines;
    foreach (x; v.array) lines ~= (x.type == JSON_TYPE.OBJECT || x.type == JSON_TYPE.ARRAY) ? pad ~ "-\n" ~ emitYAML(x, indent + 1) : pad ~ "- " ~ scalar(x);
    return lines.join("\n");
  }
  if (v.type == JSON_TYPE.OBJECT) {
    auto keys = v.object.keys.array.sort;
    string[] lines;
    foreach (k; keys) {
      auto x = v.object[k];
      lines ~= (x.type == JSON_TYPE.OBJECT || x.type == JSON_TYPE.ARRAY) ? pad ~ k ~ ":\n" ~ emitYAML(x, indent + 1) : pad ~ k ~ ": " ~ scalar(x);
    }
    return lines.join("\n");
  }
  return pad ~ scalar(v);
}

string emitTOML(JSONValue root) {
  string[] lines;
  void walk(JSONValue obj, string prefix="") {
    foreach (k; obj.object.keys.array.sort) {
      auto x = obj.object[k]; if (x.type == JSON_TYPE.OBJECT) continue; lines ~= k ~ " = " ~ scalar(x);
    }
    foreach (k; obj.object.keys.array.sort) {
      auto x = obj.object[k]; if (x.type != JSON_TYPE.OBJECT) continue;
      auto sec = prefix.length ? prefix ~ "." ~ k : k;
      if (lines.length > 0) lines ~= "";
      lines ~= "[" ~ sec ~ "]"; walk(x, sec);
    }
  }
  walk(root); return lines.join("\n");
}

string emitHCL(JSONValue v, int indent=0) {
  auto pad = indentPad(indent);
  string[] lines;
  foreach (k; v.object.keys.array.sort) {
    auto x = v.object[k];
    if (x.type == JSON_TYPE.OBJECT) lines ~= pad ~ k ~ " {\n" ~ emitHCL(x, indent + 1) ~ "\n" ~ pad ~ "}";
    else lines ~= pad ~ k ~ " = " ~ scalar(x);
  }
  return lines.join("\n");
}
