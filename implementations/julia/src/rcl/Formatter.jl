esc_str(s::String) = replace(replace(replace(replace(s, "\\"=>"\\\\"), "\""=>"\\\""), "\n"=>"\\n"), "\t"=>"\\t")
quote_str(s::String) = "\"" * esc_str(s) * "\""

function fmt_value(node)
  k = node["kind"]
  k == "string" && return quote_str(node["value"])
  k == "number" && return string(node["value"])
  k == "boolean" && return node["value"] ? "true" : "false"
  k == "array" && return "[" * join(map(fmt_value, node["elements"]), ", ") * "]"
  error("unsupported node kind: $k")
end

function fmt_block(block, indent)
  pad = repeat("  ", indent)
  head = isnothing(block["argument"]) ? "$(pad)$(block["name"]) do" : "$(pad)$(block["name"]) $(quote_str(block["argument"])) do"
  out = String[head]
  for key in block["property_order"]; push!(out, "$(pad)  $(key) = $(fmt_value(block["properties"][key]))") end
  for child in block["blocks"]; push!(out, fmt_block(child, indent + 1)) end
  for child in block["named_blocks"]; push!(out, fmt_block(child, indent + 1)) end
  push!(out, pad * "end")
  join(out, "\n")
end

format_rcl(doc) = join(map(b -> fmt_block(b, 0), doc["blocks"]), "\n\n")
