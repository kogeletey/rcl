local rcl = dofile("rcl.lua")

local src = table.concat({
  "config do",
  "  enabled = true",
  "  port = 8080",
  "  ratio = 3.14",
  "  tls.cert_path = \"/etc/cert.pem\"",
  "  names = [\"a\", \"b\", 1, false]",
  "  region \"us\" do",
  "    name = \"My Name\"",
  "  end",
  "end",
}, "\n")

local ast = rcl.parse(src)
if ast.kind ~= "document" or ast.blocks[1].name ~= "config" then error("parse") end

local obj = rcl.toObject(ast)
if obj.config.enabled ~= true then error("bool") end
if obj.config.port ~= 8080 then error("int") end
if obj.config.ratio ~= 3.14 then error("float") end
if obj.config.tls.cert_path ~= "/etc/cert.pem" then error("dot") end
if obj.config.regions.us.name ~= "My Name" then error("named") end

if not rcl.toTOML(ast):find("%[config%.regions%.us%]") then error("toml") end
if not rcl.toYAML(ast):find("regions:") then error("yaml") end
if not rcl.toHCL(ast):find("regions %{") then error("hcl") end
if not rcl.format(ast):find('region "us" do') then error("format") end

local bad = {
  "x do\n  name = value\nend",
  "x do\n  arr = [1,]\nend",
  "x do\n  a = 1\n  a = 2\nend",
  "x do\n  a = 1\n  a.b = 2\nend",
  "x do\n  name = 'bad'\nend",
  "x do\n  arr = [1,2\nend",
  "x do\n  // nope\n  a = 1\nend",
}
for _, b in ipairs(bad) do
  local ok = pcall(function() rcl.parse(b) end)
  if ok then error("expected error") end
end

print("ok")
