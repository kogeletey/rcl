import rcl; import std.stdio; import std.string;
void main(){
  auto src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
  if (!toTOML(src).canFind("[config.regions.us]")) throw new Exception("toml");
  bool ok=false; try{parse("x do\n  name = value\nend\n");} catch(Exception){ok=true;}
  if(!ok) throw new Exception("edge");
  writeln("ok");
}
