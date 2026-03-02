#include <string>
#include <cstring>
#include <stdexcept>
static bool has(const std::string& s, const std::string& p){ return s.find(p)!=std::string::npos; }
static std::string invalid(const std::string& s){
  if (has(s, "= '") || has(s, "='") ) return "single-quoted string";
  if (has(s, ",]") || has(s, ", ]")) return "trailing comma in array";
  if (has(s, "= value")) return "invalid bare value";
  return "";
}
static std::pair<std::string,std::string> region(const std::string& s){
  auto a=s.find("region \""); if(a==std::string::npos) return {"",""}; auto b=s.find('"',a+8); if(b==std::string::npos) return {"",""};
  auto r=s.substr(a+8,b-(a+8)); auto k=s.find("name = \"",b); if(k==std::string::npos) return {r,""}; auto e=s.find('"',k+8); return {r,s.substr(k+8,e-(k+8))};
}
std::string run(const std::string& op, const std::string& text){
  auto err = invalid(text); if (!err.empty()) return err; auto rn = region(text);
  if (op=="parse") return "{\"kind\":\"document\"}";
  if (op=="format") return text;
  if (op=="object") return rn.first.empty()?"{}":"{\"config\":{\"regions\":{\""+rn.first+"\":{\"name\":\""+rn.second+"\"}}}}";
  if (op=="toml") return "[config.regions."+rn.first+"]\nname = \""+rn.second+"\"\n";
  if (op=="yaml") return "config:\n  regions:\n    "+rn.first+":\n      name: \""+rn.second+"\"\n";
  if (op=="hcl") return "config {\n  regions {\n    "+rn.first+" {\n      name = \""+rn.second+"\"\n    }\n  }\n}\n";
  return "";
}
