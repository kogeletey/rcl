#ifndef RCL_H
#define RCL_H

#include "rcl_core.h"

char *rcl_format_document(const RclDocument *document);
char *rcl_to_yaml(const RclDocument *document);
char *rcl_to_toml(const RclDocument *document);
char *rcl_to_hcl(const RclDocument *document);

#endif
