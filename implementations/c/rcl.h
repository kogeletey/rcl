#ifndef RCL_H
#define RCL_H

#include <stddef.h>

typedef enum {
  RCL_VALUE_STRING,
  RCL_VALUE_NUMBER,
  RCL_VALUE_BOOLEAN,
  RCL_VALUE_ARRAY
} RclValueKind;

typedef struct RclValue RclValue;
typedef struct RclBlock RclBlock;

typedef struct {
  char *key;
  RclValue *value;
} RclProperty;

typedef struct {
  RclValue **items;
  size_t len;
} RclValueArray;

struct RclValue {
  RclValueKind kind;
  char *string_value;
  double number_value;
  int bool_value;
  RclValueArray array_value;
};

typedef enum {
  RCL_STATEMENT_PROPERTY,
  RCL_STATEMENT_BLOCK
} RclStatementKind;

typedef struct {
  RclStatementKind kind;
  RclProperty property;
  RclBlock *block;
} RclStatement;

struct RclBlock {
  char *name;
  char *argument;
  RclStatement *statements;
  size_t statement_count;
};

typedef struct {
  RclBlock **blocks;
  size_t block_count;
} RclDocument;

typedef struct {
  int ok;
  char message[96];
  size_t line;
  size_t column;
} RclError;

RclDocument *rcl_parse(const char *text, RclError *error);
void rcl_document_free(RclDocument *document);

char *rcl_format_document(const RclDocument *document);
char *rcl_to_object_json(const RclDocument *document);
char *rcl_to_yaml(const RclDocument *document);
char *rcl_to_toml(const RclDocument *document);
char *rcl_to_hcl(const RclDocument *document);

void rcl_string_free(char *text);

#endif
