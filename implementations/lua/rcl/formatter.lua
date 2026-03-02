local function esc(s)
  return s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\t", "\\t")
end

local function q(s) return '"' .. esc(s) .. '"' end

local function fmt_value(node)
  if node.kind == "string" then return q(node.value) end
  if node.kind == "number" then return tostring(node.value) end
  if node.kind == "boolean" then return node.value and "true" or "false" end
  if node.kind == "array" then
    local out = {}
    for _, e in ipairs(node.elements) do out[#out + 1] = fmt_value(e) end
    return "[" .. table.concat(out, ", ") .. "]"
  end
  error("unsupported node kind: " .. tostring(node.kind))
end

local function fmt_block(block, indent)
  local pad = string.rep("  ", indent)
  local head = block.argument and (pad .. block.name .. " " .. q(block.argument) .. " do") or (pad .. block.name .. " do")
  local lines = { head }
  for _, k in ipairs(block.property_order) do lines[#lines + 1] = pad .. "  " .. k .. " = " .. fmt_value(block.properties[k]) end
  for _, b in ipairs(block.blocks) do lines[#lines + 1] = fmt_block(b, indent + 1) end
  for _, b in ipairs(block.named_blocks) do lines[#lines + 1] = fmt_block(b, indent + 1) end
  lines[#lines + 1] = pad .. "end"
  return table.concat(lines, "\n")
end

return function(doc)
  local out = {}
  for _, b in ipairs(doc.blocks) do out[#out + 1] = fmt_block(b, 0) end
  return table.concat(out, "\n\n")
end
