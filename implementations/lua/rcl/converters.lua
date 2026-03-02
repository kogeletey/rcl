local function named_base(name) return name == "region" and "regions" or name end

local function esc(s)
  return s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\t", "\\t")
end

local function node_value(node)
  if node.kind == "array" then local out = {}; for i, e in ipairs(node.elements) do out[i] = node_value(e) end; return out end
  return node.value
end

local function insert_path(dst, key, value)
  local parts = {}
  for p in key:gmatch("[^.]+") do parts[#parts + 1] = p end
  local cur = dst
  for i = 1, #parts - 1 do
    local p = parts[i]
    if cur[p] == nil then cur[p] = {} end
    if type(cur[p]) ~= "table" then error("key conflict at '" .. p .. "'") end
    cur = cur[p]
  end
  if cur[parts[#parts]] ~= nil then error("duplicate key '" .. key .. "'") end
  cur[parts[#parts]] = value
end

local function block_object(block)
  local out = {}
  for _, k in ipairs(block.property_order) do insert_path(out, k, node_value(block.properties[k])) end
  for _, b in ipairs(block.blocks) do
    local child = block_object(b)
    if type(out[b.name]) == "table" then for k, v in pairs(child) do out[b.name][k] = v end else out[b.name] = child end
  end
  for _, b in ipairs(block.named_blocks) do
    local base = named_base(b.name)
    if type(out[base]) ~= "table" then out[base] = {} end
    out[base][b.argument] = block_object(b)
  end
  return out
end

local function scalar(v)
  if type(v) == "string" then return '"' .. esc(v) .. '"' end
  if type(v) == "boolean" then return v and "true" or "false" end
  if type(v) == "number" then return tostring(v) end
  if type(v) == "table" and #v > 0 then local out = {}; for _, e in ipairs(v) do out[#out + 1] = scalar(e) end; return "[" .. table.concat(out, ", ") .. "]" end
  if type(v) == "table" then return "{}" end
  return "null"
end

local function sorted_keys(t)
  local keys = {}
  for k, _ in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  return keys
end

local function emit_yaml(v, indent)
  local pad = string.rep("  ", indent)
  if type(v) == "table" and #v > 0 then
    local lines = {}
    for _, e in ipairs(v) do
      if type(e) == "table" then lines[#lines + 1] = pad .. "-"; lines[#lines + 1] = emit_yaml(e, indent + 1)
      else lines[#lines + 1] = pad .. "- " .. scalar(e) end
    end
    return table.concat(lines, "\n")
  elseif type(v) == "table" then
    local lines = {}
    for _, k in ipairs(sorted_keys(v)) do
      local item = v[k]
      if type(item) == "table" then lines[#lines + 1] = pad .. k .. ":"; lines[#lines + 1] = emit_yaml(item, indent + 1)
      else lines[#lines + 1] = pad .. k .. ": " .. scalar(item) end
    end
    return table.concat(lines, "\n")
  end
  return pad .. scalar(v)
end

local function emit_toml(v)
  local out = {}
  local function walk(obj, prefix)
    for _, k in ipairs(sorted_keys(obj)) do if type(obj[k]) ~= "table" or #obj[k] > 0 then out[#out + 1] = k .. " = " .. scalar(obj[k]) end end
    for _, k in ipairs(sorted_keys(obj)) do
      local item = obj[k]
      if type(item) == "table" and #item == 0 then
        local sec = prefix and (prefix .. "." .. k) or k
        if #out > 0 then out[#out + 1] = "" end
        out[#out + 1] = "[" .. sec .. "]"
        walk(item, sec)
      end
    end
  end
  walk(v, nil)
  return table.concat(out, "\n")
end

local function emit_hcl(v, indent)
  local pad, lines = string.rep("  ", indent), {}
  for _, k in ipairs(sorted_keys(v)) do
    local item = v[k]
    if type(item) == "table" and #item == 0 then lines[#lines + 1] = pad .. k .. " {"; lines[#lines + 1] = emit_hcl(item, indent + 1); lines[#lines + 1] = pad .. "}"
    else lines[#lines + 1] = pad .. k .. " = " .. scalar(item) end
  end
  return table.concat(lines, "\n")
end

return {
  to_object = function(doc)
    local out = {}
    for _, b in ipairs(doc.blocks) do
      if b.argument then out[named_base(b.name)] = { [b.argument] = block_object(b) }
      else out[b.name] = block_object(b) end
    end
    return out
  end,
  to_yaml = function(obj) return emit_yaml(obj, 0) end,
  to_toml = function(obj) return emit_toml(obj) end,
  to_hcl = function(obj) return emit_hcl(obj, 0) end,
}
