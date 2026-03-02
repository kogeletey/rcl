# rcl-c

Native C lexer, parser, AST, formatter, and converters for RCL v1.

## API

```c
#include "rcl.h"

RclError err;
RclDocument *doc = rcl_parse(text, &err);
if (doc == NULL) {
  printf("parse error: %s at %zu:%zu\n", err.message, err.line, err.column);
  return;
}

char *formatted = rcl_format_document(doc);
char *json = rcl_to_object_json(doc);
char *yaml = rcl_to_yaml(doc);
char *toml = rcl_to_toml(doc);
char *hcl = rcl_to_hcl(doc);

rcl_string_free(formatted);
rcl_string_free(json);
rcl_string_free(yaml);
rcl_string_free(toml);
rcl_string_free(hcl);
rcl_document_free(doc);
```

Named blocks are projected with the generic rule `named_base(name) = name + "s"` when `name` does not already end with `s`.
