import rcl;
import rcl.core : parseCore = parse, toObjectCore = toObject, to_object;
import std.exception : enforce;
import std.stdio : writeln;
import std.string : indexOf;

void main() {
  auto src = "config do\n"
    ~ "  enabled = true\n"
    ~ "  port = 8080\n"
    ~ "  ratio = 3.14\n"
    ~ "  tls.cert_path = \"/etc/cert.pem\"\n"
    ~ "  tests do [do name = \"smoke\" end, 1] end\n"
    ~ "  legacy = [1, 2]\n"
    ~ "  names = [\"a\", \"b\", 1, false]\n"
    ~ "  region \"us\" do\n"
    ~ "    name = \"My Name\"\n"
    ~ "  end\n"
    ~ "end\n";

  auto ast = parseCore(src);
  enforce(ast.blocks.length == 1, "parse");
  auto obj = toObjectCore(ast);
  auto objSnake = to_object(ast);
  enforce(obj.object["config"].object["tls"].object["cert_path"].str == "/etc/cert.pem", "dot");
  enforce(obj.object["config"].object["regions"].object["us"].object["name"].str == "My Name", "named");
  enforce(objSnake.object["config"].object["port"].integer == 8080, "core-to-object");
  enforce(indexOf(toTOML(ast), "[config.regions.us]") >= 0, "toml");
  enforce(indexOf(toYAML(ast), "regions:") >= 0, "yaml");
  enforce(indexOf(toHCL(ast), "regions {") >= 0, "hcl");
  auto fmt = formatRcl(ast);
  enforce(indexOf(fmt, "region \"us\" do") >= 0, "format");
  enforce(indexOf(fmt, "tests do [do name = \"smoke\" end, 1] end") >= 0, "new-array");
  enforce(indexOf(fmt, "legacy do [1, 2] end") >= 0, "old-array");

  auto rootObj = toObject(parse("do [do type = \"smoke\" end, \"string\", [1, 2, 3]]"));
  enforce(indexOf(rootObj.toString(), "\"root\":[") >= 0 && indexOf(rootObj.toString(), "\"type\":\"smoke\"") >= 0, "root-array");

  string[] bad = [
    "x do\n  name = value\nend\n",
    "x do\n  arr = [1,]\nend\n",
    "x do\n  a = 1\n  a = 2\nend\n",
    "x do\n  a = 1\n  a.b = 2\nend\n",
    "x do\n  name = 'bad'\nend\n",
    "x do\n  arr = [1,2\nend\n",
    "x do\n  // nope\n  a = 1\nend\n",
    "x do\n  tests do [\"a\", \"b\"]\nend\n",
    "do [\"a\", \"b\"",
    "x do\n  tests = [do name = \"broken\"]\nend\n",
  ];
  foreach (b; bad) {
    bool ok = false;
    try { parse(b); } catch (Exception) { ok = true; }
    enforce(ok, "expected error");
  }
  writeln("ok");
}
