package io.rcl;

final class Formatter {
  static String format(DocumentNode doc) {
    StringBuilder out = new StringBuilder();
    for (BlockNode b : doc.blocks) fmtBlock(out, b, 0);
    return out.toString();
  }

  private static void fmtBlock(StringBuilder out, BlockNode b, int n) {
    String pad = " ".repeat(n * 2);
    out.append(pad).append(b.name);
    if (b.argument != null) out.append(" ").append(q(b.argument));
    out.append(" do\n");
    for (String k : b.propertyOrder) out.append(pad).append("  ").append(k).append(" = ").append(fmtVal(b.properties.get(k))).append("\n");
    for (BlockNode c : b.blocks) fmtBlock(out, c, n + 1);
    for (BlockNode c : b.namedBlocks) fmtBlock(out, c, n + 1);
    out.append(pad).append("end\n");
  }

  private static String fmtVal(AstNode n) {
    if (n instanceof StringNode s) return q(s.value);
    if (n instanceof NumberNode d) return Double.toString(d.value);
    if (n instanceof BooleanNode b) return b.value ? "true" : "false";
    StringBuilder out = new StringBuilder("[");
    ArrayNode a = (ArrayNode) n;
    for (int i = 0; i < a.elements.size(); i++) {
      if (i > 0) out.append(", ");
      out.append(fmtVal(a.elements.get(i)));
    }
    return out.append("]").toString();
  }

  private static String q(String s) {
    return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t") + "\"";
  }
}
