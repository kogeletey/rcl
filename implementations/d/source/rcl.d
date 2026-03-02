module rcl;

public import rcl.ast;
import rcl.converters;
import rcl.formatter;
import rcl.parser;
import std.json;

Document parse(string input) { return parseDocument(input); }

string formatRcl(T)(T input) {
  auto doc = is(T == string) ? parseDocument(input) : input;
  return formatDocument(doc);
}

JSONValue toObject(T)(T input) {
  auto doc = is(T == string) ? parseDocument(input) : input;
  return toObjectDocument(doc);
}

string toYAML(T)(T input) { return emitYAML(toObject(input)); }
string toTOML(T)(T input) { return emitTOML(toObject(input)); }
string toHCL(T)(T input) { return emitHCL(toObject(input)); }
