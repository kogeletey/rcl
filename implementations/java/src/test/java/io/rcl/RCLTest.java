package io.rcl;

import java.util.List;
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

    String namedArraySrc = "config do\n  tests do [\n    do\n      name = \"case-1\"\n    end,\n    \"string\"\n  ] end\nend\n";
    Map<String, Object> namedObj = RCL.toObject(RCL.parse(namedArraySrc));
    Map<String, Object> config = (Map<String, Object>) namedObj.get("config");
    List<Object> tests = (List<Object>) config.get("tests");
    Map<String, Object> first = (Map<String, Object>) tests.get(0);
    if (!"case-1".equals(first.get("name"))) throw new RuntimeException("named array block item");
    if (!"string".equals(tests.get(1))) throw new RuntimeException("named array scalar item");

    String rootArraySrc = "do [\n  do\n    name = \"root-item\"\n  end,\n  \"x\"\n]\n";
    Map<String, Object> rootObj = RCL.toObject(RCL.parse(rootArraySrc));
    List<Object> rootVals = (List<Object>) rootObj.get("root");
    Map<String, Object> rootFirst = (Map<String, Object>) rootVals.get(0);
    if (!"root-item".equals(rootFirst.get("name"))) throw new RuntimeException("root array block item");
    if (!"x".equals(rootVals.get(1))) throw new RuntimeException("root array scalar item");

    DocumentNode coreAst = io.rcl.core.RCL.parse(src);
    if (!"document".equals(coreAst.kind())) throw new RuntimeException("core ast");
    Map<String, Object> coreObj = io.rcl.core.RCL.toObject(coreAst);
    Map<String, Object> coreRoot = (Map<String, Object>) coreObj.get("root");
    Map<String, Object> coreServices = (Map<String, Object>) coreRoot.get("services");
    Map<String, Object> coreApi = (Map<String, Object>) coreServices.get("api");
    if (!"My Name".equals(coreApi.get("title"))) throw new RuntimeException("core projection");

    Class<?> coreType = io.rcl.core.RCL.class;
    if (findMethod(coreType, "format")) throw new RuntimeException("core format leaked");
    if (findMethod(coreType, "toYAML")) throw new RuntimeException("core yaml leaked");
    if (findMethod(coreType, "toTOML")) throw new RuntimeException("core toml leaked");
    if (findMethod(coreType, "toHCL")) throw new RuntimeException("core hcl leaked");

    expectErr("do [1] end\n", "unexpected token after root array");
    expectErr("x do\n  arr do [1]\n  y = 1\nend\n", "unexpected token");
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

  private static boolean findMethod(Class<?> type, String name) {
    for (var method : type.getDeclaredMethods()) if (name.equals(method.getName())) return true;
    return false;
  }
}
