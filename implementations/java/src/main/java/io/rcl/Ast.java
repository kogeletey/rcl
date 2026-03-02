package io.rcl;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

interface AstNode { String kind(); }

final class StringNode implements AstNode {
  final String value;
  StringNode(String v) { value = v; }
  public String kind() { return "string"; }
}

final class NumberNode implements AstNode {
  final double value;
  NumberNode(double v) { value = v; }
  public String kind() { return "number"; }
}

final class BooleanNode implements AstNode {
  final boolean value;
  BooleanNode(boolean v) { value = v; }
  public String kind() { return "boolean"; }
}

final class ArrayNode implements AstNode {
  final List<AstNode> elements = new ArrayList<>();
  public String kind() { return "array"; }
}

final class BlockNode implements AstNode {
  final String name;
  final String argument;
  final LinkedHashMap<String, AstNode> properties = new LinkedHashMap<>();
  final List<String> propertyOrder = new ArrayList<>();
  final List<BlockNode> blocks = new ArrayList<>();
  final List<BlockNode> namedBlocks = new ArrayList<>();

  BlockNode(String n, String a) { name = n; argument = a; }
  public String kind() { return "block"; }
}
