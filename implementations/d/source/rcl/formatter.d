module rcl.formatter;

import std.array : appender;
import std.conv : to;
import rcl.ast;

string indentPad(int indent) {
  string pad;
  foreach (_; 0 .. indent) pad ~= "  ";
  return pad;
}

string esc(string s) {
  auto o = appender!string();
  foreach (ch; s) {
    if (ch == '\\') o.put("\\\\");
    else if (ch == '"') o.put("\\\"");
    else if (ch == '\n') o.put("\\n");
    else if (ch == '\t') o.put("\\t");
    else o.put(ch);
  }
  return o.data;
}

string q(string s) { return "\"" ~ esc(s) ~ "\""; }

string fmtValue(AstNode n) {
  final switch (n.kind) {
    case NodeKind.str: return q(n.sval);
    case NodeKind.num: return n.isInt ? (cast(long) n.nval).to!string : n.nval.to!string;
    case NodeKind.boolv: return n.bval ? "true" : "false";
    case NodeKind.arr:
      string[] parts;
      foreach (e; n.elems) parts ~= fmtValue(e);
      return "[" ~ parts.join(", ") ~ "]";
  }
}

string fmtBlock(BlockNode b, int indent) {
  auto pad = indentPad(indent);
  auto head = b.hasArg ? pad ~ b.name ~ " " ~ q(b.arg) ~ " do" : pad ~ b.name ~ " do";
  string[] lines = [head];
  foreach (k; b.propOrder) lines ~= pad ~ "  " ~ k ~ " = " ~ fmtValue(b.props[k]);
  foreach (c; b.blocks) lines ~= fmtBlock(c, indent + 1);
  foreach (c; b.named) lines ~= fmtBlock(c, indent + 1);
  lines ~= pad ~ "end";
  return lines.join("\n");
}

string formatDocument(Document d) {
  string[] lines;
  foreach (b; d.blocks) lines ~= fmtBlock(b, 0);
  return lines.join("\n\n");
}

import std.array : join;
