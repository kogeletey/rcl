#include "rcl_parser_state.h"

#include <stdlib.h>
#include <string.h>

static RclValue *parse_array(Parser *p) {
  RclValue *value = (RclValue *)calloc(1, sizeof(RclValue));
  if (value == NULL) return NULL;
  value->kind = RCL_VALUE_ARRAY;
  if (!parser_next(p)) return NULL;
  if (p->current.kind == TOK_RBRACKET) {
    parser_next(p);
    return value;
  }
  while (1) {
    RclValue *item = parser_parse_value(p);
    RclValue **next = item == NULL ? NULL : (RclValue **)realloc(value->array_value.items, sizeof(RclValue *) * (value->array_value.len + 1));
    if (next == NULL) return NULL;
    value->array_value.items = next;
    value->array_value.items[value->array_value.len++] = item;
    if (p->current.kind == TOK_COMMA) {
      parser_next(p);
      if (p->current.kind == TOK_RBRACKET) {
        rcl_set_error(p->error, "trailing comma in array", p->current.line, p->current.column);
        return NULL;
      }
      continue;
    }
    if (p->current.kind == TOK_RBRACKET) {
      parser_next(p);
      return value;
    }
    rcl_set_error(p->error, "missing ]", p->current.line, p->current.column);
    return NULL;
  }
}

RclValue *parser_parse_value(Parser *p) {
  RclValue *value = (RclValue *)calloc(1, sizeof(RclValue));
  if (value == NULL) return NULL;
  if (p->current.kind == TOK_STRING) {
    value->kind = RCL_VALUE_STRING;
    value->string_value = rcl_strdup(p->current.lexeme);
    parser_next(p);
    return value;
  }
  if (p->current.kind == TOK_NUMBER) {
    value->kind = RCL_VALUE_NUMBER;
    value->number_value = strtod(p->current.lexeme, NULL);
    parser_next(p);
    return value;
  }
  if (p->current.kind == TOK_IDENTIFIER) {
    if (strcmp(p->current.lexeme, "true") == 0 || strcmp(p->current.lexeme, "false") == 0) {
      value->kind = RCL_VALUE_BOOLEAN;
      value->bool_value = strcmp(p->current.lexeme, "true") == 0;
      parser_next(p);
      return value;
    }
    rcl_set_error(p->error, "invalid bare identifier value", p->current.line, p->current.column);
    return NULL;
  }
  if (p->current.kind == TOK_LBRACKET) return parse_array(p);
  rcl_set_error(p->error, "unexpected token", p->current.line, p->current.column);
  return NULL;
}

char *parser_parse_key(Parser *p) {
  size_t cap = strlen(p->current.lexeme) + 2;
  char *key = rcl_strdup(p->current.lexeme);
  if (key == NULL) return NULL;
  parser_next(p);
  while (p->current.kind == TOK_DOT) {
    size_t need;
    parser_next(p);
    if (!parser_ensure(p, TOK_IDENTIFIER, "unexpected token")) return NULL;
    need = strlen(key) + strlen(p->current.lexeme) + 2;
    if (need > cap) {
      cap = need * 2;
      key = (char *)realloc(key, cap);
      if (key == NULL) return NULL;
    }
    strcat(key, ".");
    strcat(key, p->current.lexeme);
    parser_next(p);
  }
  return key;
}
