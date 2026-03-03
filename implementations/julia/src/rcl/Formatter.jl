esc_str(s::String) = replace(replace(replace(replace(s, "\\"=>"\\\\"), "\""=>"\\\""), "\n"=>"\\n"), "\t"=>"\\t")
quote_str(s::String) = "\"" * esc_str(s) * "\""

function fmt_value(node)
  k = node["kind"]
  k == "string" && return quote_str(node["value"])
  k == "number" && return string(node["value"])
  k == "boolean" && return node["value"] ? "true" : "false"
  k == "array" && return "[" * join(map(fmt_value, node["elements"]), ", ") * "]"
  k == "block" && return fmt_anonymous_block(node["block"])
  error("unsupported node kind: $k")
end

function fmt_inline_block(block)
  head = isnothing(block["argument"]) ? "$(block["name"]) do" : "$(block["name"]) $(quote_str(block["argument"])) do"
  parts = String[]
  for key in block["property_order"]; push!(parts, "$(key) = $(fmt_value(block["properties"][key]))") end
  for child in block["blocks"]; push!(parts, fmt_inline_block(child)) end
  for child in block["named_blocks"]; push!(parts, fmt_inline_block(child)) end
  isempty(parts) ? "$(head) end" : "$(head) $(join(parts, " ")) end"
end

function fmt_anonymous_block(block)
  parts = String[]
  for key in block["property_order"]; push!(parts, "$(key) = $(fmt_value(block["properties"][key]))") end
  for child in block["blocks"]; push!(parts, fmt_inline_block(child)) end
  for child in block["named_blocks"]; push!(parts, fmt_inline_block(child)) end
  isempty(parts) ? "do end" : "do $(join(parts, " ")) end"
end

function fmt_block(block, indent)
  pad = repeat("  ", indent)
  head = isnothing(block["argument"]) ? "$(pad)$(block["name"]) do" : "$(pad)$(block["name"]) $(quote_str(block["argument"])) do"
  out = String[head]
  for key in block["property_order"]
    item = block["properties"][key]
    if item["kind"] == "array"; push!(out, "$(pad)  $(key) do $(fmt_value(item)) end")
    else push!(out, "$(pad)  $(key) = $(fmt_value(item))") end
  end
  for child in block["blocks"]; push!(out, fmt_block(child, indent + 1)) end
  for child in block["named_blocks"]; push!(out, fmt_block(child, indent + 1)) end
  push!(out, pad * "end")
  join(out, "\n")
end

function format_rcl(doc)
  if haskey(doc, "root_value") && !isnothing(doc["root_value"]) && doc["root_value"]["kind"] == "array"
    return "do " * fmt_value(doc["root_value"])
  end
  join(map(b -> fmt_block(b, 0), doc["blocks"]), "\n\n")
end
