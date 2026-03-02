import rcl;
import std.exception : enforce;
import std.stdio : writeln;
import std.string : canFind;

void main() {
  auto src = "config do\n"
    ~ "  enabled = true\n"
    ~ "  port = 8080\n"
    ~ "  ratio = 3.14\n"
    ~ "  tls.cert_path = \"/etc/cert.pem\"\n"
    ~ "  names = [\"a\", \"b\", 1, false]\n"
    ~ "  region \"us\" do\n"
    ~ "    name = \"My Name\"\n"
    ~ "  end\n"
    ~ "end\n";

  auto ast = parse(src);
  enforce(ast.blocks.length == 1, "parse");
  auto obj = toObject(ast);
  enforce(obj.object["config"].object["tls"].object["cert_path"].str == "/etc/cert.pem", "dot");
  enforce(obj.object["config"].object["regions"].object["us"].object["name"].str == "My Name", "named");
  enforce(toTOML(ast).canFind("[config.regions.us]"), "toml");
  enforce(toYAML(ast).canFind("regions:"), "yaml");
  enforce(toHCL(ast).canFind("regions {"), "hcl");
  enforce(formatRcl(ast).canFind("region \"us\" do"), "format");

  string[] bad = [
    "x do\n  name = value\nend\n",
    "x do\n  arr = [1,]\nend\n",
    "x do\n  a = 1\n  a = 2\nend\n",
    "x do\n  a = 1\n  a.b = 2\nend\n",
    "x do\n  name = 'bad'\nend\n",
    "x do\n  arr = [1,2\nend\n",
    "x do\n  // nope\n  a = 1\nend\n",
  ];
  foreach (b; bad) {
    bool ok = false;
    try { parse(b); } catch (Exception) { ok = true; }
    enforce(ok, "expected error");
  }
  writeln("ok");
}
