local info = debug.getinfo(1, "S").source
local root = info:sub(2):match("^(.*)[/\\]") or "."
local function load(name) return dofile(root .. "/rcl/" .. name .. ".lua") end

local parse_impl = load("parser")
local format_impl = load("formatter")
local conv = load("converters")

local M = {}

function M.parse(text)
  return parse_impl(text)
end

function M.format(input)
  local doc = type(input) == "string" and parse_impl(input) or input
  return format_impl(doc)
end

function M.toObject(input)
  local doc = type(input) == "string" and parse_impl(input) or input
  return conv.to_object(doc)
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
