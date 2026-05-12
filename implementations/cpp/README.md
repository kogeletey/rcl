# rcl-cpp

Native C++ lexer, parser, AST, formatter, and converters for RCL v1.

## Core API (parse + AST + to_object)

```cpp
#include "rcl_core.hpp"

rcl::Error err;
rcl::Document* doc = rcl::parse(text, err);
if (doc == nullptr) {
  std::cout << "parse error: " << err.message << " at " << err.line << ":" << err.column << "\n";
  return;
}

std::string json = rcl::to_object_json(*doc);
rcl::free_document(doc);
```

## Extended API (formatter + converters)

```cpp
#include "rcl.hpp"

std::string formatted = rcl::format_document(*doc);
std::string yaml = rcl::to_yaml(*doc);
std::string toml = rcl::to_toml(*doc);
std::string hcl = rcl::to_hcl(*doc);
```

Named blocks use the generic projection base rule: append `s` when the block name does not already end with `s`.
