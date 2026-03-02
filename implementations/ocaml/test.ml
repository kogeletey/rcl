let () =
  let src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n" in
  let toml = Rcl.to_toml src in
  if not (String.contains toml '[') then failwith "toml";
  try ignore (Rcl.parse "x do\n  name = value\nend\n"); failwith "edge" with _ -> print_endline "ok"
