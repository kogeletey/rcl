#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
char* run(const char* op, const char* text){
  char tmp[] = "rcl_c_tmpXXXXXX"; int fd = mkstemp(tmp); FILE* f = fdopen(fd,"w"); fputs(text,f); fclose(f);
  char cmd[512]; snprintf(cmd, sizeof(cmd), "ruby ../ruby/lib/rcl/bridge.rb %s < %s 2>&1", op, tmp);
  FILE* p = popen(cmd, "r"); char* out = calloc(1, 1); size_t n=0; char buf[256];
  while (fgets(buf,sizeof(buf),p)) { size_t b=strlen(buf); out=realloc(out,n+b+1); memcpy(out+n,buf,b); n+=b; out[n]=0; }
  pclose(p); remove(tmp); return out;
}
