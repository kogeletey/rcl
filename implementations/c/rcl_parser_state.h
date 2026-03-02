#ifndef RCL_PARSER_STATE_H
#define RCL_PARSER_STATE_H

#include "rcl_internal.h"

typedef struct {
  Lexer lexer;
  Token current;
  Token peek;
  int has_peek;
  RclError *error;
} Parser;

int parser_next(Parser *parser);
int parser_ensure(Parser *parser, TokenKind kind, const char *message);
RclValue *parser_parse_value(Parser *parser);
char *parser_parse_key(Parser *parser);

#endif
