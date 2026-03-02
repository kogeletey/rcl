# rcl-cpp

Native C++ lexer, parser, AST, formatter, and converters for RCL v1.

## API

```cpp
#include "rcl.hpp"

rcl::Error err;
rcl::Document* doc = rcl::parse(text, err);
if (doc == nullptr) {
  std::cout << "parse error: " << err.message << " at " << err.line << ":" << err.column << "\n";
  return;
}

std::string formatted = rcl::format_document(*doc);
std::string json = rcl::to_object_json(*doc);
std::string yaml = rcl::to_yaml(*doc);
std::string toml = rcl::to_toml(*doc);
std::string hcl = rcl::to_hcl(*doc);

rcl::free_document(doc);
```

Named blocks use the generic projection base rule: append `s` when the block name does not already end with `s`.
