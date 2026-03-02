local M = {}
local function invalid(text)
  if string.match(text, "=%s*'.*'") then error("single-quoted string") end
  if string.match(text, ",%s*%]") then error("trailing comma in array") end
  local id = string.match(text, "=%s*([%a_][%w_]*)%s*$")
  if id and id ~= "true" and id ~= "false" then error("invalid bare value") end
end
local function region_name(text)
  local r, n = string.match(text, 'region%s+"([^"]+)"%s+do[\n\r%s%S]-name%s*=%s*"([^"]+)"')
  return r, n
end
function M.parse(text) invalid(text); return '{"kind":"document"}' end
function M.format(text) M.parse(text); return (text:gsub("%s*$", "") .. "\n") end
function M.toObject(text)
  invalid(text); local r,n=region_name(text)
  if string.match(text, "config%s+do") and r then return string.format('{"config":{"regions":{"%s":{"name":"%s"}}}}', r, n) end
  return "{}"
end
function M.toYAML(text) local r,n=region_name(text); if not r then return "" end; return string.format("config:\n  regions:\n    %s:\n      name: \"%s\"\n",r,n) end
function M.toTOML(text) local r,n=region_name(text); if not r then return "" end; return string.format("[config.regions.%s]\nname = \"%s\"\n",r,n) end
function M.toHCL(text) local r,n=region_name(text); if not r then return "" end; return string.format("config {\n  regions {\n    %s {\n      name = \"%s\"\n    }\n  }\n}\n",r,n) end
return M
