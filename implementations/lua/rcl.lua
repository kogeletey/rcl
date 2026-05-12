local info = debug.getinfo(1, "S").source
local root = info:sub(2):match("^(.*)[/\\]") or "."
return dofile(root .. "/rcl/extended.lua")
