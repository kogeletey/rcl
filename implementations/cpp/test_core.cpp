#include "rcl_core.hpp"

#include <iostream>

static bool has(const std::string& text, const std::string& part) {
  return text.find(part) != std::string::npos;
}

int main() {
  const std::string src =
      "root do\n"
      "  service \"api\" do\n"
      "    title = \"My Name\"\n"
      "  end\n"
      "end\n";

  rcl::Error err;
  rcl::Document* doc = rcl::parse(src, err);
  if (doc == nullptr || !err.ok) return 1;

  const std::string json = rcl::to_object_json(*doc);
  if (!has(json, "\"services\":{\"api\"")) return 1;

  rcl::free_document(doc);
  std::cout << "ok\n";
  return 0;
}
