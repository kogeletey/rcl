#include "rcl_internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  char *data;
  size_t len;
  size_t cap;
} Builder;

static int append(Builder *b, const char *s) {
  size_t n = strlen(s);
  if (b->len + n + 1 > b->cap) {
    size_t cap = b->cap == 0 ? 128 : b->cap;
    while (cap < b->len + n + 1) cap *= 2;
    b->data = (char *)realloc(b->data, cap);
    if (b->data == NULL) return 0;
    b->cap = cap;
  }
  memcpy(b->data + b->len, s, n + 1);
  b->len += n;
  return 1;
}

static int scalar(Builder *b, const ObjValue *v) {
  size_t i;
  char num[32], *q;
  if (v->kind == OBJ_STRING) {
    q = escape_string(v->string_value);
    i = append(b, q);
    free(q);
    return (int)i;
  }
  if (v->kind == OBJ_NUMBER) {
    snprintf(num, sizeof(num), "%.15g", v->number_value);
    return append(b, num);
  }
  if (v->kind == OBJ_BOOLEAN) return append(b, v->bool_value ? "true" : "false");
  if (v->kind == OBJ_ARRAY) {
    if (!append(b, "[")) return 0;
    for (i = 0; i < v->array_len; i++) {
      if (i > 0 && !append(b, ", ")) return 0;
      if (!scalar(b, v->array_items[i])) return 0;
    }
    return append(b, "]");
  }
  return append(b, "{}");
}

static int json(Builder *b, const ObjValue *v) {
  size_t i;
  if (v->kind != OBJ_OBJECT) return scalar(b, v);
  if (!append(b, "{")) return 0;
  for (i = 0; i < v->entry_len; i++) {
    char *q = escape_string(v->entries[i].key);
    if (i > 0 && !append(b, ",")) return 0;
    if (!append(b, q) || !append(b, ":") || !json(b, v->entries[i].value)) return 0;
    free(q);
  }
  return append(b, "}");
}

char *rcl_to_object_json(const RclDocument *document) {
  Builder b = {0};
  ObjValue *root = rcl_project(document);
  if (root == NULL || !json(&b, root)) {
    obj_free(root);
    free(b.data);
    return NULL;
  }
  obj_free(root);
  return b.data;
}

static int yaml_obj(Builder *b, const ObjValue *v, size_t indent) {
  size_t i, j;
  for (i = 0; i < v->entry_len; i++) {
    for (j = 0; j < indent; j++) if (!append(b, "  ")) return 0;
    if (!append(b, v->entries[i].key) || !append(b, ":")) return 0;
    if (v->entries[i].value->kind == OBJ_OBJECT) {
      if (!append(b, "\n") || !yaml_obj(b, v->entries[i].value, indent + 1)) return 0;
    } else {
      if (!append(b, " ") || !scalar(b, v->entries[i].value) || !append(b, "\n")) return 0;
    }
  }
  return 1;
}

char *rcl_to_yaml(const RclDocument *document) {
  Builder b = {0};
  ObjValue *root = rcl_project(document);
  if (root == NULL || !yaml_obj(&b, root, 0)) {
    obj_free(root);
    free(b.data);
    return NULL;
  }
  obj_free(root);
  return b.data;
}

static int toml_walk(Builder *b, const ObjValue *obj, const char *prefix) {
  size_t i;
  char header[256], child[256];
  if (prefix[0] != '\0' && !append(b, "[") ) return 0;
  if (prefix[0] != '\0' && (!append(b, prefix) || !append(b, "]\n"))) return 0;
  for (i = 0; i < obj->entry_len; i++) {
    if (obj->entries[i].value->kind == OBJ_OBJECT) continue;
    if (!append(b, obj->entries[i].key) || !append(b, " = ") || !scalar(b, obj->entries[i].value) || !append(b, "\n")) return 0;
  }
  for (i = 0; i < obj->entry_len; i++) {
    if (obj->entries[i].value->kind != OBJ_OBJECT) continue;
    if (!append(b, "\n")) return 0;
    if (prefix[0] == '\0') snprintf(header, sizeof(header), "%s", obj->entries[i].key);
    else snprintf(header, sizeof(header), "%s.%s", prefix, obj->entries[i].key);
    snprintf(child, sizeof(child), "%s", header);
    if (!toml_walk(b, obj->entries[i].value, child)) return 0;
  }
  return 1;
}

char *rcl_to_toml(const RclDocument *document) {
  Builder b = {0};
  ObjValue *root = rcl_project(document);
  if (root == NULL || !toml_walk(&b, root, "")) {
    obj_free(root);
    free(b.data);
    return NULL;
  }
  obj_free(root);
  return b.data;
}

static int hcl_obj(Builder *b, const ObjValue *v, size_t indent) {
  size_t i, j;
  for (i = 0; i < v->entry_len; i++) {
    for (j = 0; j < indent; j++) if (!append(b, "  ")) return 0;
    if (v->entries[i].value->kind == OBJ_OBJECT) {
      if (!append(b, v->entries[i].key) || !append(b, " {\n")) return 0;
      if (!hcl_obj(b, v->entries[i].value, indent + 1)) return 0;
      for (j = 0; j < indent; j++) if (!append(b, "  ")) return 0;
      if (!append(b, "}\n")) return 0;
    } else {
      if (!append(b, v->entries[i].key) || !append(b, " = ") || !scalar(b, v->entries[i].value) || !append(b, "\n")) return 0;
    }
  }
  return 1;
}

char *rcl_to_hcl(const RclDocument *document) {
  Builder b = {0};
  ObjValue *root = rcl_project(document);
  if (root == NULL || !hcl_obj(&b, root, 0)) {
    obj_free(root);
    free(b.data);
    return NULL;
  }
  obj_free(root);
  return b.data;
}
