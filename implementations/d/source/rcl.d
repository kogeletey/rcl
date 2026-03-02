module rcl;
import std.process : executeShell;
import std.file : write, remove;
import std.path : buildPath;
import std.conv : to;
string run(string op, string text) {
  auto tmp = "rcl_d_tmp.txt";
  write(tmp, text);
  auto cmd = "ruby ../ruby/lib/rcl/bridge.rb " ~ op ~ " < " ~ tmp;
  auto r = executeShell(cmd);
  remove(tmp);
  if (r.status != 0) throw new Exception(r.output);
  return r.output;
}
string parse(string s){return run("parse", s);} string formatRcl(string s){return run("format", s);} 
string toObject(string s){return run("object", s);} string toYAML(string s){return run("yaml", s);} 
string toTOML(string s){return run("toml", s);} string toHCL(string s){return run("hcl", s);} 
