#include "rcl_core.h"

#include <stdio.h>
#include <string.h>

static int contains(const char *text, const char *part) { return strstr(text, part) != NULL; }

int main(void) {
  const char *src =
      "root do\n"
      "  service \"api\" do\n"
      "    title = \"My Name\"\n"
      "  end\n"
      "end\n";

  RclError err;
  RclDocument *doc = rcl_parse(src, &err);
  if (doc == NULL || !err.ok) return 1;

  char *json = rcl_to_object_json(doc);
  if (!contains(json, "\"services\":{\"api\"")) return 1;

  rcl_string_free(json);
  rcl_document_free(doc);
  puts("ok");
  return 0;
}
