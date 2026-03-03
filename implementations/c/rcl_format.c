#include "rcl_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *data;
  size_t len;
  size_t cap;
} StringBuilder;

static int sb_append(StringBuilder *sb, const char *text) {
  size_t n = strlen(text);
  if (sb->len + n + 1 > sb->cap) {
    size_t cap = sb->cap == 0 ? 128 : sb->cap;
    while (cap < sb->len + n + 1) cap *= 2;
    sb->data = (char *)realloc(sb->data, cap);
    if (sb->data == NULL) return 0;
    sb->cap = cap;
  }
  memcpy(sb->data + sb->len, text, n + 1);
  sb->len += n;
  return 1;
}

char *escape_string(const char *text) {
  size_t i, len = 2;
  char *out;
  for (i = 0; text[i] != '\0'; i++) {
    if (text[i] == '"' || text[i] == '\\' || text[i] == '\n' || text[i] == '\t') len += 2;
    else len++;
  }
  out = (char *)malloc(len + 1);
  if (out == NULL) return NULL;
  len = 0;
  out[len++] = '"';
  for (i = 0; text[i] != '\0'; i++) {
    if (text[i] == '"') {
      out[len++] = '\\';
      out[len++] = '"';
    } else if (text[i] == '\\') {
      out[len++] = '\\';
      out[len++] = '\\';
    } else if (text[i] == '\n') {
      out[len++] = '\\';
      out[len++] = 'n';
    } else if (text[i] == '\t') {
      out[len++] = '\\';
      out[len++] = 't';
    } else {
      out[len++] = text[i];
    }
  }
  out[len++] = '"';
  out[len] = '\0';
  return out;
}

static int format_value(const RclValue *value, StringBuilder *sb);

static int format_inline_block(const RclBlock *block, StringBuilder *sb) {
  size_t i;
  if (!sb_append(sb, "do")) return 0;
  for (i = 0; i < block->statement_count; i++) {
    if (!sb_append(sb, " ")) return 0;
    if (block->statements[i].kind == RCL_STATEMENT_PROPERTY) {
      if (!sb_append(sb, block->statements[i].property.key)) return 0;
      if (block->statements[i].property.value->kind == RCL_VALUE_ARRAY) {
        if (!sb_append(sb, " do ")) return 0;
        if (!format_value(block->statements[i].property.value, sb)) return 0;
        if (!sb_append(sb, " end")) return 0;
      } else {
        if (!sb_append(sb, " = ")) return 0;
        if (!format_value(block->statements[i].property.value, sb)) return 0;
      }
    } else {
      char *qarg = NULL;
      if (!sb_append(sb, block->statements[i].block->name)) return 0;
      if (block->statements[i].block->argument != NULL) {
        qarg = escape_string(block->statements[i].block->argument);
        if (qarg == NULL || !sb_append(sb, " ") || !sb_append(sb, qarg)) {
          free(qarg);
          return 0;
        }
        free(qarg);
      }
      if (!sb_append(sb, " ")) return 0;
      if (!format_inline_block(block->statements[i].block, sb)) return 0;
    }
  }
  return sb_append(sb, " end");
}

static int format_value(const RclValue *value, StringBuilder *sb) {
  size_t i;
  char num[32];
  char *quoted;
  if (value->kind == RCL_VALUE_STRING) {
    quoted = escape_string(value->string_value);
    if (quoted == NULL) return 0;
    i = sb_append(sb, quoted);
    free(quoted);
    return (int)i;
  }
  if (value->kind == RCL_VALUE_NUMBER) {
    snprintf(num, sizeof(num), "%.15g", value->number_value);
    return sb_append(sb, num);
  }
  if (value->kind == RCL_VALUE_BOOLEAN) return sb_append(sb, value->bool_value ? "true" : "false");
  if (value->kind == RCL_VALUE_BLOCK) return format_inline_block(value->block_value, sb);
  if (!sb_append(sb, "[")) return 0;
  for (i = 0; i < value->array_value.len; i++) {
    if (i > 0 && !sb_append(sb, ", ")) return 0;
    if (!format_value(value->array_value.items[i], sb)) return 0;
  }
  return sb_append(sb, "]");
}

static int format_block(const RclBlock *block, size_t indent, StringBuilder *sb) {
  size_t i;
  char pad[128];
  char *qarg;
  memset(pad, ' ', sizeof(pad));
  pad[indent * 2 < sizeof(pad) ? indent * 2 : sizeof(pad) - 1] = '\0';
  if (!sb_append(sb, pad) || !sb_append(sb, block->name)) return 0;
  if (block->argument != NULL) {
    qarg = escape_string(block->argument);
    if (qarg == NULL || !sb_append(sb, " ") || !sb_append(sb, qarg)) {
      free(qarg);
      return 0;
    }
    free(qarg);
  }
  if (!sb_append(sb, " do\n")) return 0;
  for (i = 0; i < block->statement_count; i++) {
    if (block->statements[i].kind == RCL_STATEMENT_PROPERTY) {
      if (!sb_append(sb, pad) || !sb_append(sb, "  ") || !sb_append(sb, block->statements[i].property.key)) return 0;
      if (block->statements[i].property.value->kind == RCL_VALUE_ARRAY) {
        if (!sb_append(sb, " do ")) return 0;
        if (!format_value(block->statements[i].property.value, sb)) return 0;
        if (!sb_append(sb, " end\n")) return 0;
      } else {
        if (!sb_append(sb, " = ")) return 0;
        if (!format_value(block->statements[i].property.value, sb) || !sb_append(sb, "\n")) return 0;
      }
    } else {
      if (!format_block(block->statements[i].block, indent + 1, sb)) return 0;
    }
  }
  return sb_append(sb, pad) && sb_append(sb, "end\n");
}

char *rcl_format_document(const RclDocument *document) {
  size_t i;
  StringBuilder sb = {0};
  if (document->has_root_value) {
    if (!sb_append(&sb, "do ") || !format_value(document->root_value, &sb)) {
      free(sb.data);
      return NULL;
    }
    return sb.data;
  }
  for (i = 0; i < document->block_count; i++) {
    if (!format_block(document->blocks[i], 0, &sb)) {
      free(sb.data);
      return NULL;
    }
  }
  return sb.data;
}
