using System;
using System.Collections.Generic;
using RCLImpl;

class Test {
  static int Main() {
    var src = "root do\n  service \"api\" do\n    title = \"My Name\"\n    ok = true\n    nums = [1, -2, 3.5]\n  end\nend\n";
    var ast = RCL.Parse(src);
    if (ast.Kind != "document") return 1;
    var outp = RCL.Format(ast);
    if (RCL.Parse(outp).Blocks.Count != ast.Blocks.Count) return 1;

    var obj = RCL.ToObject(ast);
    var root = (Dictionary<string, object>)obj["root"];
    var services = (Dictionary<string, object>)root["services"];
    var api = (Dictionary<string, object>)services["api"];
    if ((string)api["title"] != "My Name") return 1;
    if (!RCL.ToTOML(ast).Contains("[root.services.api]")) return 1;
    if (!RCL.ToYAML(ast).Contains("services:")) return 1;
    if (!RCL.ToHCL(ast).Contains("services {")) return 1;

    if (!Err("x do\n  name = value\nend\n", "invalid bare identifier value")) return 1;
    if (!Err("x do\n  arr = [1,]\nend\n", "trailing comma in array")) return 1;
    if (!Err("x do\n  a = 1\n  a = 2\nend\n", "duplicate key")) return 1;
    if (!Err("x do\n  a = 1\n  a.b = 2\nend\n", "key-path prefix conflict")) return 1;
    if (!Err("x do\n  a.b = 1\n  a = 2\nend\n", "key-path prefix conflict")) return 1;
    if (!Err("x do\n  s = \"bad\\q\"\nend\n", "invalid escape")) return 1;
    if (!Err("x do\n  s = \"ok\"\n", "missing end")) return 1;
    if (!Err("x do\n  a = [1,2\nend\n", "missing ]")) return 1;
    if (!Err("x do\n  s = \"bad\nend\n", "unterminated string")) return 1;
    if (!Err("x do\n  s = 'bad'\nend\n", "single-quoted string usage")) return 1;
    if (!Err("x do\n  @ = 1\nend\n", "unexpected character")) return 1;

    var namedArraySrc = "config do\n  tests do [\n    do\n      name = \"case-1\"\n    end,\n    \"string\"\n  ] end\nend\n";
    var namedArrayAst = RCL.Parse(namedArraySrc);
    var namedArrayObj = RCL.ToObject(namedArrayAst);
    var cfg = (Dictionary<string, object>)namedArrayObj["config"];
    var tests = (List<object>)cfg["tests"];
    var first = (Dictionary<string, object>)tests[0];
    if ((string)first["name"] != "case-1") return 1;
    if ((string)tests[1] != "string") return 1;

    var rootArraySrc = "do [\n  do\n    name = \"root-item\"\n  end,\n  \"x\"\n]\n";
    var rootArrayAst = RCL.Parse(rootArraySrc);
    var rootArrayObj = RCL.ToObject(rootArrayAst);
    var rootValues = (List<object>)rootArrayObj["root"];
    var rootFirst = (Dictionary<string, object>)rootValues[0];
    if ((string)rootFirst["name"] != "root-item") return 1;
    if ((string)rootValues[1] != "x") return 1;

    var coreAst = RCLImpl.Core.RCL.Parse(src);
    if (coreAst.Kind != "document") return 1;
    var coreObj = RCLImpl.Core.RCL.ToObject(coreAst);
    var coreRoot = (Dictionary<string, object>)coreObj["root"];
    var coreServices = (Dictionary<string, object>)coreRoot["services"];
    var coreApi = (Dictionary<string, object>)coreServices["api"];
    if ((string)coreApi["title"] != "My Name") return 1;

    var coreType = typeof(RCLImpl.Core.RCL);
    if (coreType.GetMethod("Format") != null) return 1;
    if (coreType.GetMethod("ToYAML") != null) return 1;
    if (coreType.GetMethod("ToTOML") != null) return 1;
    if (coreType.GetMethod("ToHCL") != null) return 1;

    Console.WriteLine("ok");
    return 0;
  }

  static bool Err(string src, string msg) {
    try { RCL.Parse(src); return false; }
    catch (Exception ex) { return ex.Message.Contains(msg) && ex.Message.Contains("line"); }
  }
}
