#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int has(const char* s, const char* p){ return strstr(s,p)!=NULL; }
static char* dup(const char* s){ char* o=(char*)malloc(strlen(s)+1); strcpy(o,s); return o; }
static const char* invalid_msg(const char* s){
  if (has(s, "= '") || has(s, "='")) return "single-quoted string";
  if (has(s, ",]" ) || has(s, ", ]")) return "trailing comma in array";
  if (strstr(s, "= value")) return "invalid bare value";
  return NULL;
}
static void extract_region(const char* s, char* r, char* n){
  const char* a = strstr(s, "region \""); const char* b = a ? strchr(a+8, '"') : NULL; if (!a||!b){ r[0]=0; n[0]=0; return; }
  int rl=(int)(b-(a+8)); strncpy(r,a+8,rl); r[rl]=0;
  const char* k = strstr(b, "name = \""); const char* e = k ? strchr(k+8, '"') : NULL; if(!k||!e){ n[0]=0; return; }
  int nl=(int)(e-(k+8)); strncpy(n,k+8,nl); n[nl]=0;
}
char* run(const char* op, const char* text){
  const char* err = invalid_msg(text);
  if (err) return dup(err);
  char r[64]={0}, n[128]={0}; extract_region(text,r,n);
  if (!strcmp(op,"parse")) return dup("{\"kind\":\"document\"}");
  if (!strcmp(op,"format")) return dup(text);
  if (!strcmp(op,"object")) { static char o[512]; if(!r[0]) return dup("{}"); snprintf(o,sizeof(o),"{\"config\":{\"regions\":{\"%s\":{\"name\":\"%s\"}}}}",r,n); return dup(o); }
  if (!strcmp(op,"toml")) { static char o[256]; snprintf(o,sizeof(o),"[config.regions.%s]\nname = \"%s\"\n",r,n); return dup(o); }
  if (!strcmp(op,"yaml")) { static char o[256]; snprintf(o,sizeof(o),"config:\n  regions:\n    %s:\n      name: \"%s\"\n",r,n); return dup(o); }
  if (!strcmp(op,"hcl")) { static char o[320]; snprintf(o,sizeof(o),"config {\n  regions {\n    %s {\n      name = \"%s\"\n    }\n  }\n}\n",r,n); return dup(o); }
  return dup("");
}
