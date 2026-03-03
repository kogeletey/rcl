package io.rcl;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

final class Converters {
  static Map<String, Object> toObject(DocumentNode doc) {
    if (doc.rootValue != null) {
      Map<String, Object> root = new LinkedHashMap<>();
      root.put("root", val(doc.rootValue));
      return root;
    }
    Map<String, Object> out = new LinkedHashMap<>();
    for (BlockNode b : doc.blocks) {
      if (b.argument == null) out.put(b.name, blockObj(b));
      else {
        Map<String, Object> x = new LinkedHashMap<>();
        x.put(b.argument, blockObj(b));
        out.put(base(b.name), x);
      }
    }
    return out;
  }

  private static Map<String, Object> blockObj(BlockNode b) {
    Map<String, Object> out = new LinkedHashMap<>();
    for (String k : b.propertyOrder) putPath(out, k, val(b.properties.get(k)));
    for (BlockNode c : b.blocks) mergeAt(out, c.name, blockObj(c));
    for (BlockNode c : b.namedBlocks) {
      String bn = base(c.name);
      Map<String, Object> m = castMap(out.getOrDefault(bn, new LinkedHashMap<>()));
      m.put(c.argument, blockObj(c));
      out.put(bn, m);
    }
    return out;
  }

  private static void putPath(Map<String, Object> out, String k, Object v) {
    String[] p = k.split("\\.");
    Map<String, Object> cur = out;
    for (int i = 0; i < p.length - 1; i++) cur = castMap(cur.computeIfAbsent(p[i], z -> new LinkedHashMap<>()));
    cur.put(p[p.length - 1], v);
  }

  private static void mergeAt(Map<String, Object> out, String k, Map<String, Object> v) {
    Map<String, Object> c = castMap(out.getOrDefault(k, new LinkedHashMap<>()));
    c.putAll(v);
    out.put(k, c);
  }

  private static Object val(AstNode n) {
    if (n instanceof StringNode s) return s.value;
    if (n instanceof NumberNode d) return d.value;
    if (n instanceof BooleanNode b) return b.value;
    if (n instanceof BlockNode b) return blockObj(b);
    List<Object> a = new ArrayList<>();
    for (AstNode x : ((ArrayNode) n).elements) a.add(val(x));
    return a;
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> castMap(Object x) { return (Map<String, Object>) x; }
  private static String base(String n) { return n.endsWith("s") ? n : n + "s"; }

  static String toYAML(DocumentNode doc) { return yaml(toObject(doc), 0); }
  static String toTOML(DocumentNode doc) { StringBuilder o = new StringBuilder(); toml(o, toObject(doc), ""); return o.toString(); }
  static String toHCL(DocumentNode doc) { return hcl(toObject(doc), 0); }

  private static String yaml(Map<String, Object> m, int n) {
    StringBuilder o = new StringBuilder();
    for (var e : m.entrySet()) {
      String p = " ".repeat(n * 2);
      if (e.getValue() instanceof Map<?, ?> mm) o.append(p).append(e.getKey()).append(":\n").append(yaml(castMap(mm), n + 1));
      else o.append(p).append(e.getKey()).append(": ").append(scalar(e.getValue())).append("\n");
    }
    return o.toString();
  }

  private static void toml(StringBuilder o, Map<String, Object> m, String p) {
    if (!p.isEmpty()) o.append("[").append(p).append("]\n");
    for (var e : m.entrySet()) if (!(e.getValue() instanceof Map<?, ?>)) o.append(e.getKey()).append(" = ").append(scalar(e.getValue())).append("\n");
    for (var e : m.entrySet()) if (e.getValue() instanceof Map<?, ?> mm) {
      o.append("\n");
      toml(o, castMap(mm), p.isEmpty() ? e.getKey() : p + "." + e.getKey());
    }
  }

  private static String hcl(Map<String, Object> m, int n) {
    StringBuilder o = new StringBuilder();
    for (var e : m.entrySet()) {
      String p = " ".repeat(n * 2);
      if (e.getValue() instanceof Map<?, ?> mm) o.append(p).append(e.getKey()).append(" {\n").append(hcl(castMap(mm), n + 1)).append(p).append("}\n");
      else o.append(p).append(e.getKey()).append(" = ").append(scalar(e.getValue())).append("\n");
    }
    return o.toString();
  }

  private static String scalar(Object v) {
    if (v instanceof String s) return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t") + "\"";
    if (v instanceof Boolean b) return b ? "true" : "false";
    if (v instanceof List<?> a) {
      StringBuilder o = new StringBuilder("[");
      for (int i = 0; i < a.size(); i++) { if (i > 0) o.append(", "); o.append(scalar(a.get(i))); }
      return o.append("]").toString();
    }
    return String.valueOf(v);
  }
}
