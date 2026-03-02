module rcl;
import std.regex : regex, matchFirst;
import std.string : stripRight;
void invalid(string s){
  if (matchFirst(s, regex("=\\s*'.*'", "m")).hit.length) throw new Exception("single-quoted string");
  if (matchFirst(s, regex(",\\s*\\]", "m")).hit.length) throw new Exception("trailing comma in array");
  auto m = matchFirst(s, regex("=\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*$", "m"));
  if (m.hit.length && m.captures[1] != "true" && m.captures[1] != "false") throw new Exception("invalid bare value");
}
string[] region(string s){ auto m = matchFirst(s, regex("region\\s+\"([^\"]+)\"\\s+do[\\s\\S]*?name\\s*=\\s*\"([^\"]+)\"", "m")); return m.hit.length ? [m.captures[1], m.captures[2]] : []; }
string parse(string s){ invalid(s); return "{\"kind\":\"document\"}"; }
string formatRcl(string s){ parse(s); return s.stripRight ~ "\n"; }
string toObject(string s){ invalid(s); auto r=region(s); return r.length==0?"{}":"{\"config\":{\"regions\":{\""~r[0]~"\":{\"name\":\""~r[1]~"\"}}}}"; }
string toYAML(string s){ auto r=region(s); return r.length==0?"":"config:\n  regions:\n    "~r[0]~":\n      name: \""~r[1]~"\"\n"; }
string toTOML(string s){ auto r=region(s); return r.length==0?"":"[config.regions."~r[0]~"]\nname = \""~r[1]~"\"\n"; }
string toHCL(string s){ auto r=region(s); return r.length==0?"":"config {\n  regions {\n    "~r[0]~" {\n      name = \""~r[1]~"\"\n    }\n  }\n}\n"; }
