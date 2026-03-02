#include <iostream>
#include <string>
std::string run(const std::string&, const std::string&);
int main(){
  std::string src="config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
  if (run("toml",src).find("[config.regions.us]")==std::string::npos) return 1;
  if (run("parse","x do\n  name = value\nend\n").find("invalid")==std::string::npos) return 1;
  std::cout<<"ok\n"; return 0;
}
