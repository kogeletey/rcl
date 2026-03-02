import rcl;
import std.exception : enforce;
import std.stdio : writeln;
import std.string : indexOf;

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
  enforce(indexOf(toTOML(ast), "[config.regions.us]") >= 0, "toml");
  enforce(indexOf(toYAML(ast), "regions:") >= 0, "yaml");
  enforce(indexOf(toHCL(ast), "regions {") >= 0, "hcl");
  enforce(indexOf(formatRcl(ast), "region \"us\" do") >= 0, "format");

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
