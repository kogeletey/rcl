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
  let ast = Rcl.Core.parse src in
  if List.length ast.blocks <> 1 then failwith "parse";
  let obj = Rcl.Core.to_object ast in
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
  let _typed_num : Rcl.Core.num = Rcl.I 1 in
  let arr_src = String.concat "\n" [
    "config do";
    "  tests do [";
    "    do";
    "      name = \"case-1\"";
    "    end,";
    "    \"string\"";
    "  ] end";
    "end";
  ] in
  let arr_obj = Rcl.to_object (Rcl.parse arr_src) in
  let cfg2 = getm "config" (VO arr_obj) in
  let tests = getm "tests" cfg2 in
  (match tests with
  | VA (VO first :: VS second :: _) ->
    if getm "name" (VO first) <> VS "case-1" then failwith "anon block in array";
    if second <> "string" then failwith "named array assignment"
  | _ -> failwith "tests shape");
  let root_src = String.concat "\n" [
    "do [";
    "  do";
    "    name = \"root-item\"";
    "  end,";
    "  \"x\"";
    "]";
  ] in
  let root_obj = Rcl.to_object (Rcl.parse root_src) in
  let rootv = getm "root" (VO root_obj) in
  (match rootv with
  | VA (VO first :: VS second :: _) ->
    if getm "name" (VO first) <> VS "root-item" then failwith "root array object";
    if second <> "x" then failwith "root array value"
  | _ -> failwith "root shape");
  let bad = [
    "x do\n  name = value\nend";
    "x do\n  arr = [1,]\nend";
    "x do\n  a = 1\n  a = 2\nend";
    "x do\n  a = 1\n  a.b = 2\nend";
    "x do\n  name = 'bad'\nend";
    "x do\n  arr = [1,2\nend";
    "x do\n  // nope\n  a = 1\nend";
    "x do\n  tests do [1, 2]\nend";
    "do [1, 2";
    "x do\n  arr = [do\n    a = 1\n]\nend";
  ] in
  List.iter (fun b -> try ignore (Rcl.parse b); failwith "expected error" with Failure _ -> ()) bad;
  print_endline "ok"
