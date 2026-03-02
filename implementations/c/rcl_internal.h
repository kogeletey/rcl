#ifndef RCL_INTERNAL_H
#define RCL_INTERNAL_H

#include "rcl.h"

typedef enum {
  TOK_EOF,
  TOK_IDENTIFIER,
  TOK_STRING,
  TOK_NUMBER,
  TOK_DO,
  TOK_END,
  TOK_EQUAL,
  TOK_COMMA,
  TOK_DOT,
  TOK_LBRACKET,
  TOK_RBRACKET
} TokenKind;

typedef struct {
  TokenKind kind;
  char *lexeme;
  size_t line;
  size_t column;
} Token;

typedef struct {
  const char *input;
  size_t pos;
  size_t line;
  size_t column;
} Lexer;

typedef enum { OBJ_STRING, OBJ_NUMBER, OBJ_BOOLEAN, OBJ_ARRAY, OBJ_OBJECT } ObjKind;

typedef struct ObjValue ObjValue;
typedef struct { char *key; ObjValue *value; } ObjEntry;

struct ObjValue {
  ObjKind kind;
  char *string_value;
  double number_value;
  int bool_value;
  ObjValue **array_items;
  size_t array_len;
  ObjEntry *entries;
  size_t entry_len;
};

void rcl_set_error(RclError *error, const char *message, size_t line, size_t column);
int rcl_is_identifier_start(char c);
int rcl_is_identifier_char(char c);
char *rcl_strdup(const char *s);
char *rcl_strndup(const char *s, size_t len);

void lexer_init(Lexer *lexer, const char *text);
int lexer_next(Lexer *lexer, Token *token, RclError *error);
void token_free(Token *token);

RclDocument *parse_document(const char *text, RclError *error);
char *escape_string(const char *text);
char *named_base(const char *name);
ObjValue *rcl_project(const RclDocument *document);
void obj_free(ObjValue *value);

#endif
