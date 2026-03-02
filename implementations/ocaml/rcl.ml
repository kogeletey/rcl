let run op text =
  let tmp = Filename.temp_file "rcl" ".txt" in
  let oc = open_out tmp in output_string oc text; close_out oc;
  let cmd = "ruby ../ruby/lib/rcl/bridge.rb " ^ op ^ " < " ^ tmp in
  let ic = Unix.open_process_in cmd in
  let b = Buffer.create 256 in
  (try while true do Buffer.add_string b (input_line ic); Buffer.add_char b '\n' done with End_of_file -> ());
  ignore (Unix.close_process_in ic); Sys.remove tmp; Buffer.contents b
let parse s = run "parse" s
let format_rcl s = run "format" s
let to_object s = run "object" s
let to_yaml s = run "yaml" s
let to_toml s = run "toml" s
let to_hcl s = run "hcl" s
