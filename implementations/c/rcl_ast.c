#include "rcl_internal.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

void rcl_set_error(RclError *error, const char *message, size_t line, size_t column) {
  if (error == NULL) return;
  error->ok = 0;
  strncpy(error->message, message, sizeof(error->message) - 1);
  error->message[sizeof(error->message) - 1] = '\0';
  error->line = line;
  error->column = column;
}

int rcl_is_identifier_start(char c) {
  return isalpha((unsigned char)c) || c == '_';
}

int rcl_is_identifier_char(char c) {
  return isalnum((unsigned char)c) || c == '_';
}

char *rcl_strdup(const char *s) {
  size_t n = strlen(s);
  char *out = (char *)malloc(n + 1);
  if (out == NULL) return NULL;
  memcpy(out, s, n + 1);
  return out;
}

char *rcl_strndup(const char *s, size_t len) {
  char *out = (char *)malloc(len + 1);
  if (out == NULL) return NULL;
  memcpy(out, s, len);
  out[len] = '\0';
  return out;
}

static void block_free(RclBlock *block);

static void value_free(RclValue *value) {
  size_t i;
  if (value == NULL) return;
  free(value->string_value);
  for (i = 0; i < value->array_value.len; i++) value_free(value->array_value.items[i]);
  free(value->array_value.items);
  block_free(value->block_value);
  free(value);
}

static void block_free(RclBlock *block) {
  size_t i;
  if (block == NULL) return;
  free(block->name);
  free(block->argument);
  for (i = 0; i < block->statement_count; i++) {
    if (block->statements[i].kind == RCL_STATEMENT_PROPERTY) {
      free(block->statements[i].property.key);
      value_free(block->statements[i].property.value);
    } else {
      block_free(block->statements[i].block);
    }
  }
  free(block->statements);
  free(block);
}

void rcl_document_free(RclDocument *document) {
  size_t i;
  if (document == NULL) return;
  value_free(document->root_value);
  for (i = 0; i < document->block_count; i++) block_free(document->blocks[i]);
  free(document->blocks);
  free(document);
}

void rcl_string_free(char *text) { free(text); }
