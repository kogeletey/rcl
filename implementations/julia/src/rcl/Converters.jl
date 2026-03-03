named_base(name::String) = endswith(name, "s") ? name : string(name, "s")
node_value(node) = node["kind"] == "array" ? map(node_value, node["elements"]) : node["kind"] == "block" ? block_object(node["block"]) : node["value"]

function insert_path!(dst::Dict{String,Any}, key::String, value)
  parts = split(key, ".")
  cur = dst
  for i in 1:length(parts)-1
    p = parts[i]
    if !haskey(cur, p); cur[p] = Dict{String,Any}() end
    cur[p] isa Dict{String,Any} || error("key conflict at '$p'")
    cur = cur[p]
  end
  haskey(cur, parts[end]) && error("duplicate key '$key'")
  cur[parts[end]] = value
end

function block_object(block)
  out = Dict{String,Any}()
  for key in block["property_order"]; insert_path!(out, key, node_value(block["properties"][key])) end
  for child in block["blocks"]
    c = block_object(child)
    if get(out, child["name"], nothing) isa Dict{String,Any}; merge!(out[child["name"]], c) else out[child["name"]] = c end
  end
  for child in block["named_blocks"]
    base = named_base(child["name"])
    if !(get(out, base, nothing) isa Dict{String,Any}); out[base] = Dict{String,Any}() end
    out[base][child["argument"]] = block_object(child)
  end
  out
end

function to_object_doc(doc)
  if haskey(doc, "root_value") && !isnothing(doc["root_value"])
    return Dict{String,Any}("root" => node_value(doc["root_value"]))
  end
  out = Dict{String,Any}()
  for block in doc["blocks"]
    if isnothing(block["argument"]); out[block["name"]] = block_object(block)
    else out[named_base(block["name"])] = Dict{String,Any}(block["argument"] => block_object(block)) end
  end
  out
end

esc_scalar(s::String) = "\"" * replace(replace(replace(replace(s, "\\"=>"\\\\"), "\""=>"\\\""), "\n"=>"\\n"), "\t"=>"\\t") * "\""
scalar(v) = v isa String ? esc_scalar(v) : v isa Bool ? (v ? "true" : "false") : v isa Number ? string(v) : v isa Vector ? "[" * join(map(scalar, v), ", ") * "]" : v isa Dict{String,Any} ? "{}" : "{}"

function emit_yaml(v, indent=0)
  pad = repeat("  ", indent)
  if v isa Vector
    return join(map(x -> x isa Dict{String,Any} || x isa Vector ? "$(pad)-\n$(emit_yaml(x, indent + 1))" : "$(pad)- $(scalar(x))", v), "\n")
  elseif v isa Dict{String,Any}
    keys_sorted = sort(collect(keys(v)))
    return join(map(k -> begin item = v[k]; item isa Dict{String,Any} || item isa Vector ? "$(pad)$(k):\n$(emit_yaml(item, indent + 1))" : "$(pad)$(k): $(scalar(item))" end, keys_sorted), "\n")
  end
  pad * scalar(v)
end

function emit_toml(v::Dict{String,Any})
  out = String[]
  function walk(obj::Dict{String,Any}, prefix=nothing)
    for k in sort(collect(keys(obj)))
      item = obj[k]
      (item isa Dict{String,Any}) && continue
      push!(out, "$k = $(scalar(item))")
    end
    for k in sort(collect(keys(obj)))
      item = obj[k]
      (item isa Dict{String,Any}) || continue
      sec = isnothing(prefix) ? k : "$(prefix).$(k)"
      !isempty(out) && push!(out, "")
      push!(out, "[$sec]")
      walk(item, sec)
    end
  end
  walk(v)
  join(out, "\n")
end

function emit_hcl(v::Dict{String,Any}, indent=0)
  pad, lines = repeat("  ", indent), String[]
  for k in sort(collect(keys(v)))
    item = v[k]
    if item isa Dict{String,Any}
      push!(lines, "$(pad)$(k) {")
      push!(lines, emit_hcl(item, indent + 1))
      push!(lines, "$(pad)}")
    else
      push!(lines, "$(pad)$(k) = $(scalar(item))")
    end
  end
  join(lines, "\n")
end
