#include <stdio.h>
#include <string.h>
char* run(const char*, const char*);
int main(){
  const char* src="config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
  char* t=run("toml",src); if(!strstr(t,"[config.regions.us]")) return 1;
  char* b=run("parse","x do\n  name = value\nend\n"); if (strstr(b,"invalid") == NULL) return 1;
  puts("ok"); return 0;
}
