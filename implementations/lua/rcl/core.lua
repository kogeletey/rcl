local info = debug.getinfo(1, "S").source
local base = info:sub(2):match("^(.*)[/\\]") or "."
local function load(name) return dofile(base .. "/" .. name .. ".lua") end

local parse_impl = load("parser")
local conv = load("converters")

local M = {
  types = {
    DOCUMENT = "document",
    BLOCK = "block",
    STRING = "string",
    NUMBER = "number",
    BOOLEAN = "boolean",
    ARRAY = "array",
  }
}

function M.parse(text)
  return parse_impl(text)
end

function M.toObject(input)
  local doc = type(input) == "string" and parse_impl(input) or input
  return conv.to_object(doc)
end

M.to_object = M.toObject

return M
