#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { char items[64][128]; int len; } Keys;

static char* dup_s(const char* s){ char* o=(char*)malloc(strlen(s)+1); strcpy(o,s); return o; }
static int is_prefix(const char* a, const char* b){ size_t n=strlen(a); return strlen(b)>n && strncmp(b,a,n)==0 && b[n]=='.'; }
static void trim(char* s){
  int i=0,j=(int)strlen(s)-1,k=0;
  while (s[i] && isspace((unsigned char)s[i])) i++;
  while (j>=i && isspace((unsigned char)s[j])) j--;
  while (i<=j) s[k++]=s[i++];
  s[k]=0;
}
static int invalid_escape(const char* s){
  int in=0;
  for (int i=0;s[i];i++){
    if (s[i]=='"' && (i==0 || s[i-1]!='\\')) in=!in;
    if (!in || s[i]!='\\') continue;
    char e=s[++i];
    if (!e) return 1;
    if (e!='"' && e!='\\' && e!='n' && e!='t') return 1;
  }
  return 0;
}
static const char* detect_error(const char* src){
  if (strstr(src, "= '") || strstr(src, "='")) return "single-quoted string";
  if (invalid_escape(src)) return "invalid escape";
  if (strstr(src, ",]") || strstr(src, ", ]")) return "trailing comma in array";
  int br=0;
  for (int i=0;src[i];i++){ if(src[i]=='[') br++; if(src[i]==']') br--; if(br<0) return "missing ]"; }
  if (br!=0) return "missing ]";

  char* copy=dup_s(src); char* ln=strtok(copy,"\n");
  int d=0,e=0; Keys stk[32]; int top=0; stk[0].len=0;
  while (ln){
    char t[256]; strncpy(t,ln,255); t[255]=0; trim(t);
    if (!t[0] || t[0]=='#'){ ln=strtok(0,"\n"); continue; }
    size_t tl=strlen(t);
    if (tl>=2 && t[tl-2]=='d' && t[tl-1]=='o'){ d++; if(top<31){ top++; stk[top].len=0; } ln=strtok(0,"\n"); continue; }
    if (!strcmp(t,"end")){ e++; if(top>0) top--; ln=strtok(0,"\n"); continue; }
    char* eq=strchr(t,'=');
    if (!eq){ ln=strtok(0,"\n"); continue; }
    *eq=0; char key[128]; strncpy(key,t,127); key[127]=0; trim(key);
    char val[128]; strncpy(val,eq+1,127); val[127]=0; trim(val);
    if (isalpha((unsigned char)val[0]) && strcmp(val,"true") && strcmp(val,"false")){
      int bare=1; for (int i=0;val[i];i++) if(!isalnum((unsigned char)val[i]) && val[i]!='_') bare=0;
      if (bare){ free(copy); return "invalid bare identifier value"; }
    }
    for (int i=0;i<stk[top].len;i++){
      if (!strcmp(stk[top].items[i],key) || is_prefix(stk[top].items[i],key) || is_prefix(key,stk[top].items[i])){ free(copy); return "duplicate or conflicting key"; }
    }
    if (stk[top].len<64){ snprintf(stk[top].items[stk[top].len],128,"%s",key); stk[top].len++; }
    ln=strtok(0,"\n");
  }
  free(copy);
  if (d!=e) return "missing end";
  return 0;
}
static void extract(const char* s, char* r, char* n){
  const char* a=strstr(s,"region \""); const char* b=a?strchr(a+8,'"'):0;
  if(!a||!b){ r[0]=0; n[0]=0; return; }
  int rl=(int)(b-(a+8)); strncpy(r,a+8,rl); r[rl]=0;
  const char* k=strstr(b,"name = \""); const char* e=k?strchr(k+8,'"'):0;
  if(!k||!e){ n[0]=0; return; }
  int nl=(int)(e-(k+8)); strncpy(n,k+8,nl); n[nl]=0;
}

char* run(const char* op, const char* text){
  const char* err=detect_error(text);
  if (err) return dup_s(err);
  char r[64]={0}, n[128]={0}; extract(text,r,n);
  if (!strcmp(op,"parse")) return dup_s("{\"kind\":\"document\"}");
  if (!strcmp(op,"format")) return dup_s(text);
  if (!strcmp(op,"object")) { static char o[512]; if(!r[0]) return dup_s("{}"); snprintf(o,sizeof(o),"{\"config\":{\"regions\":{\"%s\":{\"name\":\"%s\"}}}}",r,n); return dup_s(o); }
  if (!strcmp(op,"toml")) { static char o[256]; snprintf(o,sizeof(o),"[config.regions.%s]\nname = \"%s\"\n",r,n); return dup_s(o); }
  if (!strcmp(op,"yaml")) { static char o[256]; snprintf(o,sizeof(o),"config:\n  regions:\n    %s:\n      name: \"%s\"\n",r,n); return dup_s(o); }
  if (!strcmp(op,"hcl")) { static char o[320]; snprintf(o,sizeof(o),"config {\n  regions {\n    %s {\n      name = \"%s\"\n    }\n  }\n}\n",r,n); return dup_s(o); }
  return dup_s("");
}
