#ifndef RCL_CPP_PROJECT_HPP
#define RCL_CPP_PROJECT_HPP

#include "rcl.hpp"

#include <map>
#include <string>
#include <vector>

namespace rcl {

enum class ObjKind { String, Number, Boolean, Array, Object };

struct Obj {
  ObjKind kind = ObjKind::Object;
  std::string string_value;
  double number_value = 0.0;
  bool bool_value = false;
  std::vector<Obj> array_value;
  std::map<std::string, Obj> object_value;
};

Obj project(const Document& doc);
std::string named_base(const std::string& name);

}

#endif
