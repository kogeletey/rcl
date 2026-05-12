module rcl.core;

public import rcl.ast;
import rcl.converters;
import rcl.parser;
import std.json;

Document parse(string input) { return parseDocument(input); }

JSONValue toObject(T)(T input) {
  static if (is(T == string)) return toObjectDocument(parseDocument(input));
  else return toObjectDocument(input);
}

JSONValue to_object(T)(T input) { return toObject(input); }
