#include "rcl_internal.h"

#include <stdlib.h>
#include <string.h>

static char cur(const Lexer *lexer) { return lexer->input[lexer->pos]; }
static int eof(const Lexer *lexer) { return lexer->input[lexer->pos] == '\0'; }

static void advance(Lexer *lexer) {
  if (eof(lexer)) return;
  if (cur(lexer) == '\n') {
    lexer->line++;
    lexer->column = 1;
  } else {
    lexer->column++;
  }
  lexer->pos++;
}

static void skip(Lexer *lexer) {
  while (!eof(lexer)) {
    if (cur(lexer) == '#') {
      while (!eof(lexer) && cur(lexer) != '\n') advance(lexer);
      continue;
    }
    if (cur(lexer) == ' ' || cur(lexer) == '\t' || cur(lexer) == '\r' || cur(lexer) == '\n') {
      advance(lexer);
      continue;
    }
    break;
  }
}

void lexer_init(Lexer *lexer, const char *text) {
  lexer->input = text;
  lexer->pos = 0;
  lexer->line = 1;
  lexer->column = 1;
}

void token_free(Token *token) {
  free(token->lexeme);
  token->lexeme = NULL;
}

static int token_simple(Lexer *lexer, Token *token, TokenKind kind, char ch) {
  token->kind = kind;
  token->line = lexer->line;
  token->column = lexer->column;
  token->lexeme = rcl_strndup(&ch, 1);
  advance(lexer);
  return token->lexeme != NULL;
}

static int lex_identifier(Lexer *lexer, Token *token) {
  size_t start = lexer->pos, line = lexer->line, col = lexer->column;
  while (!eof(lexer) && rcl_is_identifier_char(cur(lexer))) advance(lexer);
  token->lexeme = rcl_strndup(lexer->input + start, lexer->pos - start);
  token->line = line;
  token->column = col;
  if (token->lexeme == NULL) return 0;
  if (strcmp(token->lexeme, "do") == 0) token->kind = TOK_DO;
  else if (strcmp(token->lexeme, "end") == 0) token->kind = TOK_END;
  else token->kind = TOK_IDENTIFIER;
  return 1;
}

static int lex_number(Lexer *lexer, Token *token) {
  size_t start = lexer->pos, line = lexer->line, col = lexer->column;
  if (cur(lexer) == '-') advance(lexer);
  while (!eof(lexer) && cur(lexer) >= '0' && cur(lexer) <= '9') advance(lexer);
  if (cur(lexer) == '.') {
    advance(lexer);
    if (cur(lexer) < '0' || cur(lexer) > '9') return 0;
    while (!eof(lexer) && cur(lexer) >= '0' && cur(lexer) <= '9') advance(lexer);
  }
  token->kind = TOK_NUMBER;
  token->line = line;
  token->column = col;
  token->lexeme = rcl_strndup(lexer->input + start, lexer->pos - start);
  return token->lexeme != NULL;
}

static int lex_string(Lexer *lexer, Token *token, RclError *error) {
  size_t line = lexer->line, col = lexer->column, cap = 32, len = 0;
  char *out = (char *)malloc(cap);
  if (out == NULL) return 0;
  advance(lexer);
  while (!eof(lexer) && cur(lexer) != '"') {
    char ch = cur(lexer);
    if (ch == '\\') {
      advance(lexer);
      if (eof(lexer)) {
        free(out);
        rcl_set_error(error, "unterminated string", line, col);
        return -1;
      }
      ch = cur(lexer);
      if (ch == '"') ch = '"';
      else if (ch == '\\') ch = '\\';
      else if (ch == 'n') ch = '\n';
      else if (ch == 't') ch = '\t';
      else {
        free(out);
        rcl_set_error(error, "invalid escape", lexer->line, lexer->column);
        return -1;
      }
    }
    if (len + 2 > cap) {
      cap *= 2;
      out = (char *)realloc(out, cap);
      if (out == NULL) return 0;
    }
    out[len++] = ch;
    advance(lexer);
  }
  if (eof(lexer)) {
    free(out);
    rcl_set_error(error, "unterminated string", line, col);
    return -1;
  }
  advance(lexer);
  out[len] = '\0';
  token->kind = TOK_STRING;
  token->line = line;
  token->column = col;
  token->lexeme = out;
  return 1;
}

int lexer_next(Lexer *lexer, Token *token, RclError *error) {
  skip(lexer);
  token->lexeme = NULL;
  if (eof(lexer)) {
    token->kind = TOK_EOF;
    token->line = lexer->line;
    token->column = lexer->column;
    return 1;
  }
  if (rcl_is_identifier_start(cur(lexer))) return lex_identifier(lexer, token);
  if (cur(lexer) == '-' || (cur(lexer) >= '0' && cur(lexer) <= '9')) return lex_number(lexer, token);
  if (cur(lexer) == '"') return lex_string(lexer, token, error);
  if (cur(lexer) == '\'') {
    rcl_set_error(error, "single-quoted string usage", lexer->line, lexer->column);
    return -1;
  }
  if (cur(lexer) == '=') return token_simple(lexer, token, TOK_EQUAL, '=');
  if (cur(lexer) == ',') return token_simple(lexer, token, TOK_COMMA, ',');
  if (cur(lexer) == '.') return token_simple(lexer, token, TOK_DOT, '.');
  if (cur(lexer) == '[') return token_simple(lexer, token, TOK_LBRACKET, '[');
  if (cur(lexer) == ']') return token_simple(lexer, token, TOK_RBRACKET, ']');
  rcl_set_error(error, "unexpected character", lexer->line, lexer->column);
  return -1;
}
