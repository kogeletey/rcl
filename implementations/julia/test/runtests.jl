include("../src/RCL.jl")
include("../src/RCLCore.jl")
using .RCL
using .RCLCore

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

core_ast = RCLCore.parse(src)
core_ast["kind"] == "document" || error("core parse")
core_obj = RCLCore.to_object(src)
core_obj["config"]["regions"]["us"]["name"] == "My Name" || error("core object")
isdefined(RCLCore, :format) && error("core must not export format")
isdefined(RCLCore, :to_yaml) && error("core must not export converters")

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

array_src = join([
  "config do",
  "  tests do [",
  "    do",
  "      name = \"case-1\"",
  "    end,",
  "    \"string\"",
  "  ] end",
  "end",
], "\n")
array_obj = RCL.to_object(array_src)
array_obj["config"]["tests"][1]["name"] == "case-1" || error("anon block in array")
array_obj["config"]["tests"][2] == "string" || error("named array assignment")
occursin("tests do [", RCL.format(array_src)) || error("named array format")

root_src = join([
  "do [",
  "  do",
  "    name = \"root-item\"",
  "  end,",
  "  \"x\"",
  "]",
], "\n")
root_obj = RCL.to_object(root_src)
root_obj["root"][1]["name"] == "root-item" || error("root array object")
root_obj["root"][2] == "x" || error("root array value")

bad = [
  "x do\n  name = value\nend",
  "x do\n  arr = [1,]\nend",
  "x do\n  a = 1\n  a = 2\nend",
  "x do\n  a = 1\n  a.b = 2\nend",
  "x do\n  name = 'bad'\nend",
  "x do\n  arr = [1,2\nend",
  "x do\n  // nope\n  a = 1\nend",
  "x do\n  tests do [1, 2]\nend",
  "do [1, 2",
  "x do\n  arr = [do\n    a = 1\n]\nend",
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
