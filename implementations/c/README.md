# rcl-c

Native C lexer, parser, AST, formatter, and converters for RCL v1.

## Core API (parse + AST + to_object)

```c
#include "rcl_core.h"

RclError err;
RclDocument *doc = rcl_parse(text, &err);
if (doc == NULL) {
  printf("parse error: %s at %zu:%zu\n", err.message, err.line, err.column);
  return;
}

char *json = rcl_to_object_json(doc);
rcl_string_free(json);
rcl_document_free(doc);
```

## Extended API (formatter + converters)

```c
#include "rcl.h"

char *formatted = rcl_format_document(doc);
char *yaml = rcl_to_yaml(doc);
char *toml = rcl_to_toml(doc);
char *hcl = rcl_to_hcl(doc);
```

Named blocks are projected with the generic rule `named_base(name) = name + "s"` when `name` does not already end with `s`.
