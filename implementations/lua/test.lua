local rcl = dofile("rcl.lua")
local core = dofile("rcl/core.lua")
local extended = dofile("rcl/extended.lua")

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

local core_ast = core.parse(src)
if core_ast.kind ~= core.types.DOCUMENT then error("core-parse") end

local obj = rcl.toObject(ast)
local core_obj = core.to_object(core_ast)
if obj.config.enabled ~= true then error("bool") end
if obj.config.port ~= 8080 then error("int") end
if obj.config.ratio ~= 3.14 then error("float") end
if obj.config.tls.cert_path ~= "/etc/cert.pem" then error("dot") end
if obj.config.regions.us.name ~= "My Name" then error("named") end
if core_obj.config.port ~= 8080 then error("core-to-object") end

if type(core.format) ~= "nil" then error("core-surface") end
if type(extended.format) ~= "function" then error("extended-surface") end

if not rcl.toTOML(ast):find("%[config%.regions%.us%]") then error("toml") end
if not rcl.toYAML(ast):find("regions:") then error("yaml") end
if not rcl.toHCL(ast):find("regions %{") then error("hcl") end
if not rcl.format(ast):find('region "us" do') then error("format") end

local arr_src = table.concat({
  "config do",
  "  tests do [",
  "    do",
  "      name = \"case-1\"",
  "    end,",
  "    \"string\"",
  "  ] end",
  "end",
}, "\n")
local arr_obj = rcl.toObject(arr_src)
if arr_obj.config.tests[1].name ~= "case-1" then error("anon block in array") end
if arr_obj.config.tests[2] ~= "string" then error("named array assignment") end
if not rcl.format(arr_src):find("tests do %[") then error("named array format") end

local root_src = table.concat({
  "do [",
  "  do",
  "    name = \"root-item\"",
  "  end,",
  "  \"x\"",
  "]",
}, "\n")
local root_obj = rcl.toObject(root_src)
if root_obj.root[1].name ~= "root-item" then error("root array object") end
if root_obj.root[2] ~= "x" then error("root array value") end

local bad = {
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
}
for _, b in ipairs(bad) do
  local ok = pcall(function() rcl.parse(b) end)
  if ok then error("expected error") end
end

print("ok")
