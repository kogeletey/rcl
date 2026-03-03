#include "rcl_internal.h"

#include <stdlib.h>
#include <string.h>

static ObjValue *obj_new(ObjKind kind) {
  ObjValue *v = (ObjValue *)calloc(1, sizeof(ObjValue));
  if (v != NULL) v->kind = kind;
  return v;
}

static ObjValue *project_block(const RclBlock *block);

void obj_free(ObjValue *value) {
  size_t i;
  if (value == NULL) return;
  free(value->string_value);
  for (i = 0; i < value->array_len; i++) obj_free(value->array_items[i]);
  free(value->array_items);
  for (i = 0; i < value->entry_len; i++) {
    free(value->entries[i].key);
    obj_free(value->entries[i].value);
  }
  free(value->entries);
  free(value);
}

static ObjValue *obj_from_ast(const RclValue *value) {
  size_t i;
  ObjValue *child;
  ObjValue *out = obj_new((ObjKind)value->kind);
  if (out == NULL) return NULL;
  if (value->kind == RCL_VALUE_STRING) out->string_value = rcl_strdup(value->string_value);
  else if (value->kind == RCL_VALUE_NUMBER) out->number_value = value->number_value;
  else if (value->kind == RCL_VALUE_BOOLEAN) out->bool_value = value->bool_value;
  else if (value->kind == RCL_VALUE_ARRAY) {
    out->array_items = (ObjValue **)calloc(value->array_value.len, sizeof(ObjValue *));
    if (out->array_items == NULL) return NULL;
    out->array_len = value->array_value.len;
    for (i = 0; i < out->array_len; i++) out->array_items[i] = obj_from_ast(value->array_value.items[i]);
  } else {
    child = project_block(value->block_value);
    out->kind = OBJ_OBJECT;
    out->entries = child->entries;
    out->entry_len = child->entry_len;
    child->entries = NULL;
    child->entry_len = 0;
    obj_free(child);
  }
  return out;
}

static ObjValue *obj_get(ObjValue *obj, const char *key) {
  size_t i;
  for (i = 0; i < obj->entry_len; i++) if (strcmp(obj->entries[i].key, key) == 0) return obj->entries[i].value;
  return NULL;
}

static int obj_set(ObjValue *obj, const char *key, ObjValue *value) {
  size_t i;
  ObjEntry *next;
  for (i = 0; i < obj->entry_len; i++) {
    if (strcmp(obj->entries[i].key, key) == 0) {
      obj_free(obj->entries[i].value);
      obj->entries[i].value = value;
      return 1;
    }
  }
  next = (ObjEntry *)realloc(obj->entries, sizeof(ObjEntry) * (obj->entry_len + 1));
  if (next == NULL) return 0;
  obj->entries = next;
  obj->entries[obj->entry_len].key = rcl_strdup(key);
  obj->entries[obj->entry_len].value = value;
  obj->entry_len++;
  return 1;
}

char *named_base(const char *name) {
  size_t n = strlen(name);
  char *out = (char *)malloc(n + 2);
  if (out == NULL) return NULL;
  strcpy(out, name);
  if (n == 0 || name[n - 1] != 's') strcat(out, "s");
  return out;
}

static int insert_path(ObjValue *root, const char *path, ObjValue *value) {
  const char *dot = strchr(path, '.');
  char *head;
  ObjValue *next;
  if (dot == NULL) return obj_set(root, path, value);
  head = rcl_strndup(path, (size_t)(dot - path));
  if (head == NULL) return 0;
  next = obj_get(root, head);
  if (next == NULL || next->kind != OBJ_OBJECT) {
    next = obj_new(OBJ_OBJECT);
    if (next == NULL || !obj_set(root, head, next)) {
      free(head);
      return 0;
    }
  }
  free(head);
  return insert_path(next, dot + 1, value);
}

static int merge_objects(ObjValue *target, ObjValue *source) {
  size_t i;
  for (i = 0; i < source->entry_len; i++) if (!obj_set(target, source->entries[i].key, source->entries[i].value)) return 0;
  source->entry_len = 0;
  free(source->entries);
  source->entries = NULL;
  obj_free(source);
  return 1;
}

static ObjValue *project_block(const RclBlock *block) {
  size_t i;
  ObjValue *out = obj_new(OBJ_OBJECT);
  if (out == NULL) return NULL;
  for (i = 0; i < block->statement_count; i++) {
    if (block->statements[i].kind == RCL_STATEMENT_PROPERTY) {
      if (!insert_path(out, block->statements[i].property.key, obj_from_ast(block->statements[i].property.value))) return NULL;
    } else if (block->statements[i].block->argument == NULL) {
      ObjValue *current = obj_get(out, block->statements[i].block->name);
      ObjValue *child = project_block(block->statements[i].block);
      if (current != NULL && current->kind == OBJ_OBJECT) merge_objects(current, child);
      else obj_set(out, block->statements[i].block->name, child);
    } else {
      ObjValue *base_obj;
      char *base = named_base(block->statements[i].block->name);
      base_obj = obj_get(out, base);
      if (base_obj == NULL || base_obj->kind != OBJ_OBJECT) {
        base_obj = obj_new(OBJ_OBJECT);
        obj_set(out, base, base_obj);
      }
      obj_set(base_obj, block->statements[i].block->argument, project_block(block->statements[i].block));
      free(base);
    }
  }
  return out;
}

ObjValue *rcl_project(const RclDocument *document) {
  size_t i;
  ObjValue *root = obj_new(OBJ_OBJECT);
  if (root == NULL) return NULL;
  if (document->has_root_value) {
    obj_set(root, "root", obj_from_ast(document->root_value));
    return root;
  }
  for (i = 0; i < document->block_count; i++) {
    if (document->blocks[i]->argument == NULL) obj_set(root, document->blocks[i]->name, project_block(document->blocks[i]));
    else {
      ObjValue *base_obj;
      char *base = named_base(document->blocks[i]->name);
      base_obj = obj_get(root, base);
      if (base_obj == NULL || base_obj->kind != OBJ_OBJECT) {
        base_obj = obj_new(OBJ_OBJECT);
        obj_set(root, base, base_obj);
      }
      obj_set(base_obj, document->blocks[i]->argument, project_block(document->blocks[i]));
      free(base);
    }
  }
  return root;
}
