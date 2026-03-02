include("../src/RCL.jl")
using .RCL

src = join([
  "config do",
  "  enabled = true",
  "  port = 8080",
  "  ratio = 3.14",
  "  tls.cert_path = \"/etc/cert.pem\"",
  "  names = [\"a\", \"b\", 1, false]",
  "  region \"us\" do",
  "    name = \"My Name\"",
  "  end",
  "end"
], "\n")

ast = RCL.parse(src)
ast["kind"] == "document" || error("parse")
obj = RCL.to_object(ast)
obj["config"]["enabled"] == true || error("bool")
obj["config"]["tls"]["cert_path"] == "/etc/cert.pem" || error("dot")
obj["config"]["regions"]["us"]["name"] == "My Name" || error("named")
occursin("[config.regions.us]", RCL.to_toml(ast)) || error("toml")
occursin("regions:", RCL.to_yaml(ast)) || error("yaml")
occursin("regions {", RCL.to_hcl(ast)) || error("hcl")
occursin("region \"us\" do", RCL.format(ast)) || error("format")

bad = [
  "x do\n  name = value\nend",
  "x do\n  arr = [1,]\nend",
  "x do\n  a = 1\n  a = 2\nend",
  "x do\n  a = 1\n  a.b = 2\nend",
  "x do\n  name = 'bad'\nend",
  "x do\n  arr = [1,2\nend",
  "x do\n  // nope\n  a = 1\nend",
]
for b in bad
  ok = false
  try
    RCL.parse(b)
  catch
    ok = true
  end
  ok || error("expected error")
end

println("ok")
