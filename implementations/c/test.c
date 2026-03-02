#include "rcl.h"

#include <stdio.h>
#include <string.h>

static int contains(const char *text, const char *part) { return strstr(text, part) != NULL; }

static int expect_parse_error(const char *src, const char *msg) {
  RclError err;
  RclDocument *doc = rcl_parse(src, &err);
  if (doc != NULL) {
    rcl_document_free(doc);
    return 0;
  }
  return !err.ok && contains(err.message, msg) && err.line > 0 && err.column > 0;
}

int main(void) {
  const char *src =
      "root do\n"
      "  tls.cert = \"/x\"\n"
      "  service \"api\" do\n"
      "    title = \"My Name\"\n"
      "    ports = [1, 2, false]\n"
      "  end\n"
      "end\n";
  RclError err;
  RclDocument *doc = rcl_parse(src, &err);
  char *json;
  char *toml;
  char *yaml;
  char *hcl;
  char *fmt;
  RclDocument *doc2;
  if (doc == NULL || !err.ok) return 1;

  json = rcl_to_object_json(doc);
  toml = rcl_to_toml(doc);
  yaml = rcl_to_yaml(doc);
  hcl = rcl_to_hcl(doc);
  fmt = rcl_format_document(doc);
  if (!contains(json, "\"services\":{\"api\"")) return 1;
  if (!contains(toml, "[root.services.api]")) return 1;
  if (!contains(yaml, "services:")) return 1;
  if (!contains(hcl, "services {")) return 1;

  doc2 = rcl_parse(fmt, &err);
  if (doc2 == NULL || !err.ok) return 1;

  if (!expect_parse_error("x do\n  name = value\nend\n", "invalid bare identifier value")) return 1;
  if (!expect_parse_error("x do\n  arr = [1,]\nend\n", "trailing comma in array")) return 1;
  if (!expect_parse_error("x do\n  arr = [1\nend\n", "missing ]")) return 1;
  if (!expect_parse_error("x do\n  a = 1\n  a = 2\nend\n", "duplicate key")) return 1;
  if (!expect_parse_error("x do\n  a = 1\n  a.b = 2\nend\n", "prefix conflict")) return 1;
  if (!expect_parse_error("x do\n  s = \"bad\\q\"\nend\n", "invalid escape")) return 1;
  if (!expect_parse_error("x do\n  s = 'bad'\nend\n", "single-quoted string")) return 1;
  if (!expect_parse_error("x do\n", "missing end")) return 1;

  rcl_document_free(doc);
  rcl_document_free(doc2);
  rcl_string_free(json);
  rcl_string_free(toml);
  rcl_string_free(yaml);
  rcl_string_free(hcl);
  rcl_string_free(fmt);
  puts("ok");
  return 0;
}
