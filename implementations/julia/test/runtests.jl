include("../src/RCL.jl")
using .RCL
src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n"
occursin("[config.regions.us]", RCL.to_toml(src)) || error("toml")
ok = false
try RCL.parse("x do\n  name = value\nend\n") catch ok = true end
ok || error("edge")
println("ok")
