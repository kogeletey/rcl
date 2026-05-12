#ifndef RCL_CPP_HPP
#define RCL_CPP_HPP

#include "rcl_core.hpp"

namespace rcl {

std::string format_document(const Document& doc);
std::string to_yaml(const Document& doc);
std::string to_toml(const Document& doc);
std::string to_hcl(const Document& doc);

}  // namespace rcl

#endif
