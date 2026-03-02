#include <iostream>
#include <string>
std::string run(const std::string&, const std::string&);

static bool has(const std::string& s,const std::string& p){ return s.find(p)!=std::string::npos; }

int main(){
  std::string src =
    "config do\n"
    "  tls.cert = \"/x\"\n"
    "  region \"us\" do\n"
    "    name = \"My Name\"\n"
    "    ports = [1, 2]\n"
    "  end\n"
    "end\n";

  if(!has(run("object",src),"\"regions\":{\"us\":{\"name\":\"My Name\"")) return 1;
  if(!has(run("toml",src),"[config.regions.us]")) return 1;
  if(!has(run("yaml",src),"config:")) return 1;
  if(!has(run("hcl",src),"config {")) return 1;
  if(!has(run("format",src),"config do")) return 1;

  if(!has(run("parse","x do\n  name = value\nend\n"),"invalid bare identifier value")) return 1;
  if(!has(run("parse","x do\n  arr = [1,]\nend\n"),"trailing comma in array")) return 1;
  if(!has(run("parse","x do\n  a = 1\n  a.b = 2\nend\n"),"duplicate or conflicting key")) return 1;
  if(!has(run("parse","x do\n  s = 'bad'\nend\n"),"single-quoted string")) return 1;
  if(!has(run("parse","x do\n  s = \"bad\\q\"\nend\n"),"invalid escape")) return 1;

  std::cout << "ok\n";
  return 0;
}
