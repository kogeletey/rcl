#include "rcl.hpp"

namespace rcl {

namespace {

void FreeBlock(Block* block) {
  if (block == nullptr) return;
  for (auto& st : block->statements) if (st.kind == StatementKind::Block) FreeBlock(st.block);
  delete block;
}

}

void free_document(Document* doc) {
  if (doc == nullptr) return;
  for (auto* block : doc->blocks) FreeBlock(block);
  delete doc;
}

}
