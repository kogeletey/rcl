#include "rcl.hpp"

#include <iostream>

static bool has(const std::string& text, const std::string& part) {
  return text.find(part) != std::string::npos;
}

static bool expect_error(const std::string& src, const std::string& msg) {
  rcl::Error err;
  rcl::Document* doc = rcl::parse(src, err);
  if (doc != nullptr) {
    rcl::free_document(doc);
    return false;
  }
  return !err.ok && has(err.message, msg) && err.line > 0 && err.column > 0;
}

int main() {
  const std::string src =
      "root do\n"
      "  tls.cert = \"/x\"\n"
      "  tests do [do name = \"smoke\" end, 1] end\n"
      "  legacy = [1, 2]\n"
      "  service \"api\" do\n"
      "    title = \"My Name\"\n"
      "    ports = [1, 2, false]\n"
      "  end\n"
      "end\n";
  rcl::Error err;
  rcl::Document* doc = rcl::parse(src, err);
  if (doc == nullptr || !err.ok) return 1;

  const std::string json = rcl::to_object_json(*doc);
  const std::string toml = rcl::to_toml(*doc);
  const std::string yaml = rcl::to_yaml(*doc);
  const std::string hcl = rcl::to_hcl(*doc);
  const std::string fmt = rcl::format_document(*doc);
  if (!has(json, "\"services\":{\"api\"")) return 1;
  if (!has(toml, "[root.services.api]")) return 1;
  if (!has(yaml, "services:")) return 1;
  if (!has(hcl, "services {")) return 1;
  if (!has(fmt, "tests do [do name = \"smoke\" end, 1] end")) return 1;
  if (!has(fmt, "legacy do [1, 2] end")) return 1;

  rcl::Document* doc2 = rcl::parse(fmt, err);
  if (doc2 == nullptr || !err.ok) return 1;
  rcl::Document* doc3 = rcl::parse("do [do type = \"smoke\" end, \"string\", [1, 2, 3]]", err);
  if (doc3 == nullptr || !err.ok) return 1;
  const std::string json2 = rcl::to_object_json(*doc3);
  if (!has(json2, "\"root\":[") || !has(json2, "\"type\":\"smoke\"") || !has(json2, "\"string\"")) return 1;

  if (!expect_error("x do\n  name = value\nend\n", "invalid bare identifier value")) return 1;
  if (!expect_error("x do\n  arr = [1,]\nend\n", "trailing comma in array")) return 1;
  if (!expect_error("x do\n  arr = [1\nend\n", "missing ]")) return 1;
  if (!expect_error("x do\n  a = 1\n  a = 2\nend\n", "duplicate key")) return 1;
  if (!expect_error("x do\n  a = 1\n  a.b = 2\nend\n", "prefix conflict")) return 1;
  if (!expect_error("x do\n  s = \"bad\\q\"\nend\n", "invalid escape")) return 1;
  if (!expect_error("x do\n  s = 'bad'\nend\n", "single-quoted string")) return 1;
  if (!expect_error("x do\n", "missing end")) return 1;
  if (!expect_error("x do\n  tests do [\"a\", \"b\"]\nend\n", "missing end")) return 1;
  if (!expect_error("do [\"a\", \"b\"", "missing ]")) return 1;
  if (!expect_error("x do\n  tests = [do name = \"broken\"]\nend\n", "unexpected token")) return 1;

  rcl::free_document(doc);
  rcl::free_document(doc2);
  rcl::free_document(doc3);
  std::cout << "ok\n";
  return 0;
}
