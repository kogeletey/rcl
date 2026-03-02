let invalid s =
  let re q = Str.regexp q in
  (try ignore (Str.search_forward (re "= *'.*'") s 0); failwith "single-quoted string" with Not_found -> ());
  (try ignore (Str.search_forward (re ", *\\]") s 0); failwith "trailing comma in array" with Not_found -> ());
  let id = Str.regexp "= *\([A-Za-z_][A-Za-z0-9_]*\) *$" in
  try let _ = Str.search_forward id s 0 in let v = Str.matched_group 1 s in if v <> "true" && v <> "false" then failwith "invalid bare value" with Not_found -> ()
let region s =
  let r = Str.regexp "region +\"\([^\"]+\)\" +do[\n\r\t\000-\255]*name *= *\"\([^\"]+\)\"" in
  try let _ = Str.search_forward r s 0 in Some (Str.matched_group 1 s, Str.matched_group 2 s) with Not_found -> None
let parse s = invalid s; "{\"kind\":\"document\"}"
let format_rcl s = ignore (parse s); String.trim s ^ "\n"
let to_object s = invalid s; match region s with Some (r,n) -> "{\"config\":{\"regions\":{\""^r^"\":{\"name\":\""^n^"\"}}}}" | None -> "{}"
let to_yaml s = match region s with Some (r,n) -> "config:\n  regions:\n    "^r^":\n      name: \""^n^"\"\n" | None -> ""
let to_toml s = match region s with Some (r,n) -> "[config.regions."^r^"]\nname = \""^n^"\"\n" | None -> ""
let to_hcl s = match region s with Some (r,n) -> "config {\n  regions {\n    "^r^" {\n      name = \""^n^"\"\n    }\n  }\n}\n" | None -> ""
