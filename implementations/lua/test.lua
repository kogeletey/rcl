local rcl = dofile("rcl.lua")
local src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n"
local toml = rcl.toTOML(src)
if not string.find(toml, "%[config%.regions%.us%]") then error("toml") end
local ok = pcall(function() rcl.parse("x do\n  name = value\nend\n") end)
if ok then error("edge") end
print("ok")
