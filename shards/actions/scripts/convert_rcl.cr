require "option_parser"
require "../../../src/rcl"

input = ""
format = "yml"

OptionParser.parse do |p|
  p.banner = "Usage: crystal run shards/actions/scripts/convert_rcl.cr -- --input <file.rcl> --format yml|toml|hcl"
  p.on("--input PATH", "Input RCL file") { |v| input = v }
  p.on("--format FORMAT", "Output format: yml|toml|hcl") { |v| format = v.downcase }
end

raise "--input is required" if input.empty?

doc = RCL.parse_file(input)
case format
when "yml", "yaml"
  puts RCL.to_yaml(doc)
when "toml"
  puts RCL.to_toml(doc)
when "hcl"
  puts RCL.to_hcl(doc)
else
  raise "Unsupported format: #{format}"
end
