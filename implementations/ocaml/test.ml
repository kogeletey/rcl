let src = String.concat "\n" [
  "config do";
  "  enabled = true";
  "  port = 8080";
  "  ratio = 3.14";
  "  tls.cert_path = \"/etc/cert.pem\"";
  "  names = [\"a\", \"b\", 1, false]";
  "  region \"us\" do";
  "    name = \"My Name\"";
  "  end";
  "end";
]

let () =
  let ast = Rcl.parse src in
  if List.length ast <> 1 then failwith "parse";
  let obj = Rcl.to_object ast in
  let open Rcl in
  let getm k = function VO m -> SM.find k m | _ -> failwith "type" in
  let cfg = getm "config" (VO obj) in
  let tls = getm "tls" cfg in
  if getm "cert_path" tls <> VS "/etc/cert.pem" then failwith "dot";
  let regions = getm "regions" cfg in
  let us = getm "us" regions in
  if getm "name" us <> VS "My Name" then failwith "named";
  if not (String.contains (Rcl.to_toml ast) '[') then failwith "toml";
  if not (String.contains (Rcl.to_yaml ast) ':') then failwith "yaml";
  if not (String.contains (Rcl.to_hcl ast) '{') then failwith "hcl";
  if not (String.contains (Rcl.format_rcl ast) 'd') then failwith "fmt";
  let bad = [
    "x do\n  name = value\nend";
    "x do\n  arr = [1,]\nend";
    "x do\n  a = 1\n  a = 2\nend";
    "x do\n  a = 1\n  a.b = 2\nend";
    "x do\n  name = 'bad'\nend";
    "x do\n  arr = [1,2\nend";
    "x do\n  // nope\n  a = 1\nend";
  ] in
  List.iter (fun b -> try ignore (Rcl.parse b); failwith "expected error" with Failure _ -> ()) bad;
  print_endline "ok"
