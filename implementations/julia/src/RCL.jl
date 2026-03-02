module RCL
function run(op::String, text::String)
  tmp = tempname(); write(tmp, text)
  cmd = `sh -lc $("ruby ../ruby/lib/rcl/bridge.rb " * op * " < " * tmp)`
  out = read(cmd, String)
  rm(tmp; force=true)
  return out
end
parse(s)=run("parse", s); format(s)=run("format", s); to_object(s)=run("object", s)
to_yaml(s)=run("yaml", s); to_toml(s)=run("toml", s); to_hcl(s)=run("hcl", s)
end
