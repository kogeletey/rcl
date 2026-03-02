#include "rcl_parser_state.h"

#include <stdlib.h>
#include <string.h>

int parser_ensure(Parser *p, TokenKind kind, const char *message) {
  if (p->current.kind != kind) {
    rcl_set_error(p->error, message, p->current.line, p->current.column);
    return 0;
  }
  return 1;
}

int parser_next(Parser *p) {
  token_free(&p->current);
  if (p->has_peek) {
    p->current = p->peek;
    p->peek.lexeme = NULL;
    p->has_peek = 0;
    return 1;
  }
  return lexer_next(&p->lexer, &p->current, p->error) > 0;
}

static int append_statement(RclBlock *block, RclStatement statement) {
  size_t n = block->statement_count;
  RclStatement *items = (RclStatement *)realloc(block->statements, sizeof(RclStatement) * (n + 1));
  if (items == NULL) return 0;
  block->statements = items;
  block->statements[n] = statement;
  block->statement_count++;
  return 1;
}

static int is_prefix(const char *a, const char *b) {
  size_t na = strlen(a), nb = strlen(b);
  return na < nb && strncmp(a, b, na) == 0 && b[na] == '.';
}

static int key_conflict(char **keys, size_t count, const char *key) {
  size_t i;
  for (i = 0; i < count; i++) {
    if (strcmp(keys[i], key) == 0 || is_prefix(keys[i], key) || is_prefix(key, keys[i])) return 1;
  }
  return 0;
}

static RclBlock *parse_block(Parser *p);

static int parse_statement(Parser *p, RclBlock *block, char ***keys, size_t *key_count) {
  if (!parser_ensure(p, TOK_IDENTIFIER, "unexpected token")) return 0;
  if (!p->has_peek) {
    if (!lexer_next(&p->lexer, &p->peek, p->error)) return 0;
    p->has_peek = 1;
  }
  if (p->peek.kind == TOK_EQUAL || p->peek.kind == TOK_DOT) {
    RclStatement st;
    char *key = parser_parse_key(p);
    if (key == NULL) return 0;
    if (key_conflict(*keys, *key_count, key)) {
      rcl_set_error(p->error, "duplicate key or key-path prefix conflict", p->current.line, p->current.column);
      free(key);
      return 0;
    }
    if (!parser_ensure(p, TOK_EQUAL, "unexpected token")) return 0;
    if (!parser_next(p)) return 0;
    st.kind = RCL_STATEMENT_PROPERTY;
    st.property.key = key;
    st.property.value = parser_parse_value(p);
    if (st.property.value == NULL || !append_statement(block, st)) return 0;
    *keys = (char **)realloc(*keys, sizeof(char *) * (*key_count + 1));
    if (*keys == NULL) return 0;
    (*keys)[(*key_count)++] = rcl_strdup(key);
    return 1;
  }
  if (p->peek.kind == TOK_DO || p->peek.kind == TOK_STRING) {
    RclStatement st;
    st.kind = RCL_STATEMENT_BLOCK;
    st.block = parse_block(p);
    return st.block != NULL && append_statement(block, st);
  }
  rcl_set_error(p->error, "unexpected token", p->current.line, p->current.column);
  return 0;
}

static RclBlock *parse_block(Parser *p) {
  RclBlock *block = (RclBlock *)calloc(1, sizeof(RclBlock));
  char **keys = NULL;
  size_t key_count = 0;
  if (block == NULL) return NULL;
  block->name = rcl_strdup(p->current.lexeme);
  if (!parser_next(p)) return NULL;
  if (p->current.kind == TOK_STRING) {
    block->argument = rcl_strdup(p->current.lexeme);
    if (!parser_next(p)) return NULL;
  }
  if (!parser_ensure(p, TOK_DO, "unexpected token")) return NULL;
  if (!parser_next(p)) return NULL;
  while (p->current.kind != TOK_END) {
    if (p->current.kind == TOK_EOF) {
      rcl_set_error(p->error, "missing end", p->current.line, p->current.column);
      return NULL;
    }
    if (!parse_statement(p, block, &keys, &key_count)) return NULL;
  }
  if (!parser_next(p)) return NULL;
  return block;
}

RclDocument *parse_document(const char *text, RclError *error) {
  Parser parser;
  RclDocument *doc = (RclDocument *)calloc(1, sizeof(RclDocument));
  if (doc == NULL) return NULL;
  if (error != NULL) {
    error->ok = 1;
    error->message[0] = '\0';
    error->line = 0;
    error->column = 0;
  }
  lexer_init(&parser.lexer, text);
  parser.current.lexeme = NULL;
  parser.peek.lexeme = NULL;
  parser.has_peek = 0;
  parser.error = error;
  if (!parser_next(&parser)) return NULL;
  while (parser.current.kind != TOK_EOF) {
    RclBlock *block = parse_block(&parser);
    RclBlock **next = block == NULL ? NULL : (RclBlock **)realloc(doc->blocks, sizeof(RclBlock *) * (doc->block_count + 1));
    if (next == NULL) return NULL;
    doc->blocks = next;
    doc->blocks[doc->block_count++] = block;
  }
  token_free(&parser.current);
  return doc;
}

RclDocument *rcl_parse(const char *text, RclError *error) { return parse_document(text, error); }
