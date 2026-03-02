local M = {}
local function run(op, text)
  local bridge = "../ruby/lib/rcl/bridge.rb"
  local tmp = os.tmpname()
  local f = assert(io.open(tmp, "w")); f:write(text); f:close()
  local cmd = "ruby " .. bridge .. " " .. op .. " < " .. tmp
  local p = io.popen(cmd .. " 2>&1")
  local out = p:read("*a")
  local ok = p:close()
  os.remove(tmp)
  if not ok then error(out) end
  return out
end
M.parse = function(text) return run("parse", text) end
M.format = function(text) return run("format", text) end
M.toObject = function(text) return run("object", text) end
M.toYAML = function(text) return run("yaml", text) end
M.toTOML = function(text) return run("toml", text) end
M.toHCL = function(text) return run("hcl", text) end
return M
