module rcl;

public import rcl.ast;
import rcl.converters;
import rcl.formatter;
import rcl.parser;
import std.json;

Document parse(string input) { return parseDocument(input); }

string formatRcl(T)(T input) {
  static if (is(T == string)) return formatDocument(parseDocument(input));
  else return formatDocument(input);
}

JSONValue toObject(T)(T input) {
  static if (is(T == string)) return toObjectDocument(parseDocument(input));
  else return toObjectDocument(input);
}

string toYAML(T)(T input) { return emitYAML(toObject(input)); }
string toTOML(T)(T input) { return emitTOML(toObject(input)); }
string toHCL(T)(T input) { return emitHCL(toObject(input)); }
