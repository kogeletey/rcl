module rcl.converters;

import std.algorithm : sort;
import std.array : array, join;
import std.conv : to;
import std.json;
import rcl.ast;
import std.string : split, replace;

string namedBase(string n) { return n.length > 0 && n[$ - 1] == 's' ? n : n ~ "s"; }

JSONValue nodeToVal(AstNode n) {
  final switch (n.kind) {
    case NodeKind.str: return JSONValue(n.sval);
    case NodeKind.num: return n.isInt ? JSONValue(cast(long)n.nval) : JSONValue(n.nval);
    case NodeKind.boolv: return JSONValue(n.bval);
    case NodeKind.arr:
      JSONValue[] out; foreach (e; n.elems) out ~= nodeToVal(e); return JSONValue(out);
  }
}

void insertPath(ref JSONValue obj, string key, JSONValue v) {
  auto parts = key.split(".");
  auto cur = &obj;
  foreach (i, p; parts) {
    auto last = i + 1 == parts.length;
    if (last) {
      if (p in cur.object) throw new Exception("duplicate key '" ~ key ~ "'");
      cur.object[p] = v;
    } else {
      if (auto x = p in cur.object) {
        if ((*x).type != JSON_TYPE.OBJECT) throw new Exception("key conflict at '" ~ p ~ "'");
      } else cur.object[p] = JSONValue(JSONValue[string].init);
      cur = &(cur.object[p]);
    }
  }
}

JSONValue blockToObject(BlockNode b) {
  JSONValue out = JSONValue(JSONValue[string].init);
  foreach (k; b.propOrder) insertPath(out, k, nodeToVal(b.props[k]));
  foreach (c; b.blocks) {
    auto child = blockToObject(c);
    if (auto ex = c.name in out.object) {
      if ((*ex).type == JSON_TYPE.OBJECT) foreach (k, v; child.object) (*ex).object[k] = v;
      else out.object[c.name] = child;
    } else out.object[c.name] = child;
  }
  foreach (c; b.named) {
    auto base = namedBase(c.name);
    if (!(base in out.object)) out.object[base] = JSONValue(JSONValue[string].init);
    out.object[base].object[c.arg] = blockToObject(c);
  }
  return out;
}

JSONValue toObjectDocument(Document d) {
  JSONValue out = JSONValue(JSONValue[string].init);
  foreach (b; d.blocks) {
    if (b.hasArg) {
      JSONValue m = JSONValue(JSONValue[string].init);
      m.object[b.arg] = blockToObject(b);
      out.object[namedBase(b.name)] = m;
    } else out.object[b.name] = blockToObject(b);
  }
  return out;
}

string esc(string s) { return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t"); }
string scalar(JSONValue v) {
  switch (v.type) {
    case JSON_TYPE.STRING: return "\"" ~ esc(v.str) ~ "\"";
    case JSON_TYPE.INTEGER: return v.integer.to!string;
    case JSON_TYPE.UINTEGER: return v.uinteger.to!string;
    case JSON_TYPE.FLOAT: return v.floating.to!string;
    case JSON_TYPE.TRUE: return "true";
    case JSON_TYPE.FALSE: return "false";
    case JSON_TYPE.ARRAY: return "[" ~ v.array.map!(x => scalar(x)).array.join(", ") ~ "]";
    case JSON_TYPE.OBJECT: return "{}";
    case JSON_TYPE.NULL: return "null";
  }
}

string emitYAML(JSONValue v, int indent=0) {
  auto pad = "  ".repeat(indent);
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
  string[] out;
  void walk(JSONValue obj, string prefix="") {
    foreach (k; obj.object.keys.array.sort) {
      auto x = obj.object[k]; if (x.type == JSON_TYPE.OBJECT) continue; out ~= k ~ " = " ~ scalar(x);
    }
    foreach (k; obj.object.keys.array.sort) {
      auto x = obj.object[k]; if (x.type != JSON_TYPE.OBJECT) continue;
      auto sec = prefix.length ? prefix ~ "." ~ k : k;
      if (out.length) out ~= "";
      out ~= "[" ~ sec ~ "]"; walk(x, sec);
    }
  }
  walk(root); return out.join("\n");
}

string emitHCL(JSONValue v, int indent=0) {
  auto pad = "  ".repeat(indent);
  string[] out;
  foreach (k; v.object.keys.array.sort) {
    auto x = v.object[k];
    if (x.type == JSON_TYPE.OBJECT) out ~= pad ~ k ~ " {\n" ~ emitHCL(x, indent + 1) ~ "\n" ~ pad ~ "}";
    else out ~= pad ~ k ~ " = " ~ scalar(x);
  }
  return out.join("\n");
}

import std.algorithm.iteration : map, repeat;
