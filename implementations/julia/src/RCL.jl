module RCL
invalid(s) = begin
  occursin(r"=\s*'.*'"m, s) && error("single-quoted string")
  occursin(r",\s*\]"m, s) && error("trailing comma in array")
  m = match(r"=\s*([A-Za-z_][A-Za-z0-9_]*)\s*$"m, s)
  m !== nothing && !(m.captures[1] in ("true","false")) && error("invalid bare value")
end
region(s) = begin m=match(r"region\s+\"([^\"]+)\"\s+do[\s\S]*?name\s*=\s*\"([^\"]+)\""m,s); m===nothing ? nothing : (m.captures[1], m.captures[2]) end
parse(s)= (invalid(s); "{\"kind\":\"document\"}")
format(s)= (parse(s); strip(s)*"\n")
to_object(s)= (invalid(s); r=region(s); r===nothing ? "{}" : "{\"config\":{\"regions\":{\"$(r[1])\":{\"name\":\"$(r[2])\"}}}}")
to_yaml(s)= (r=region(s); r===nothing ? "" : "config:\n  regions:\n    $(r[1]):\n      name: \"$(r[2])\"\n")
to_toml(s)= (r=region(s); r===nothing ? "" : "[config.regions.$(r[1])]\nname = \"$(r[2])\"\n")
to_hcl(s)= (r=region(s); r===nothing ? "" : "config {\n  regions {\n    $(r[1]) {\n      name = \"$(r[2])\"\n    }\n  }\n}\n")
end
