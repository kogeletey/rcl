local info = debug.getinfo(1, "S").source
local root = info:sub(2):match("^(.*)[/\\]") or "."
local function load(name) return dofile(root .. "/" .. name .. ".lua") end

local core = load("core")
local format_impl = load("formatter")
local conv = load("converters")

local M = {}

M.parse = core.parse
M.toObject = core.toObject
M.to_object = core.to_object

function M.format(input)
  local doc = type(input) == "string" and core.parse(input) or input
  return format_impl(doc)
end

function M.toYAML(input)
  return conv.to_yaml(M.toObject(input))
end

function M.toTOML(input)
  return conv.to_toml(M.toObject(input))
end

function M.toHCL(input)
  return conv.to_hcl(M.toObject(input))
end

return M
