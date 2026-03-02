#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unistd.h>
std::string run(const std::string& op, const std::string& text){
  char tmp[] = "rcl_cpp_tmpXXXXXX"; int fd = mkstemp(tmp); FILE* f = fdopen(fd,"w"); fputs(text.c_str(),f); fclose(f);
  std::string cmd = "ruby ../ruby/lib/rcl/bridge.rb " + op + " < " + tmp + " 2>&1";
  FILE* p = popen(cmd.c_str(), "r"); char buf[256]; std::string out;
  while (fgets(buf,sizeof(buf),p)) out += buf;
  pclose(p); remove(tmp); return out;
}
