package io.rcl;

import java.util.Map;

public final class RCLTest {
  @SuppressWarnings("unchecked")
  public static void main(String[] args) {
    String src = "root do\n  service \"api\" do\n    title = \"My Name\"\n    ok = true\n    nums = [1, -2, 3.5]\n  end\nend\n";
    DocumentNode ast = RCL.parse(src);
    if (!"document".equals(ast.kind())) throw new RuntimeException("ast");
    String out = RCL.format(ast);
    DocumentNode rt = RCL.parse(out);
    if (rt.blocks.size() != ast.blocks.size()) throw new RuntimeException("roundtrip");

    Map<String, Object> obj = RCL.toObject(ast);
    Map<String, Object> root = (Map<String, Object>) obj.get("root");
    Map<String, Object> services = (Map<String, Object>) root.get("services");
    Map<String, Object> api = (Map<String, Object>) services.get("api");
    if (!"My Name".equals(api.get("title"))) throw new RuntimeException("projection");
    if (!RCL.toTOML(ast).contains("[root.services.api]")) throw new RuntimeException("toml");
    if (!RCL.toYAML(ast).contains("services:")) throw new RuntimeException("yaml");
    if (!RCL.toHCL(ast).contains("services {")) throw new RuntimeException("hcl");

    expectErr("x do\n  name = value\nend\n", "invalid bare identifier value");
    expectErr("x do\n  arr = [1,]\nend\n", "trailing comma in array");
    expectErr("x do\n  a = 1\n  a = 2\nend\n", "duplicate key");
    expectErr("x do\n  a = 1\n  a.b = 2\nend\n", "key-path prefix conflict");
    expectErr("x do\n  a.b = 1\n  a = 2\nend\n", "key-path prefix conflict");
    expectErr("x do\n  s = \"bad\\q\"\nend\n", "invalid escape");
    expectErr("x do\n  s = \"ok\"\n", "missing end");
    expectErr("x do\n  a = [1,2\nend\n", "missing ]");
    expectErr("x do\n  s = \"bad\nend\n", "unterminated string");
    expectErr("x do\n  s = 'bad'\nend\n", "single-quoted string usage");
    expectErr("x do\n  @ = 1\nend\n", "unexpected character");
    System.out.println("ok");
  }

  private static void expectErr(String src, String needle) {
    try {
      RCL.parse(src);
      throw new RuntimeException("expected error");
    } catch (RuntimeException ex) {
      if (!ex.getMessage().contains(needle)) throw new RuntimeException("wrong error: " + ex.getMessage());
      if (!ex.getMessage().contains("line")) throw new RuntimeException("missing position");
    }
  }
}
