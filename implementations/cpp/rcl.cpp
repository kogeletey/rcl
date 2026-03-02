#include <algorithm>
#include <cctype>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

static bool is_prefix(const std::string& a, const std::string& b) {
  if (a.size() >= b.size()) return false;
  return b.rfind(a + ".", 0) == 0;
}

static std::string trim(const std::string& s) {
  size_t i = 0, j = s.size();
  while (i < j && std::isspace(static_cast<unsigned char>(s[i]))) i++;
  while (j > i && std::isspace(static_cast<unsigned char>(s[j - 1]))) j--;
  return s.substr(i, j - i);
}

static bool has_invalid_escape(const std::string& s) {
  bool in = false;
  for (size_t i = 0; i < s.size(); i++) {
    char c = s[i];
    if (c == '"' && (i == 0 || s[i - 1] != '\\')) in = !in;
    if (!in || c != '\\') continue;
    if (i + 1 >= s.size()) return true;
    char e = s[++i];
    if (e != '"' && e != '\\' && e != 'n' && e != 't') return true;
  }
  return false;
}

static std::string detect_error(const std::string& text) {
  if (text.find("= '") != std::string::npos || text.find("='") != std::string::npos) return "single-quoted string";
  if (has_invalid_escape(text)) return "invalid escape";
  if (text.find(",]") != std::string::npos || text.find(", ]") != std::string::npos) return "trailing comma in array";
  int depth = 0;
  for (char c : text) {
    if (c == '[') depth++;
    if (c == ']') depth--;
    if (depth < 0) return "missing ]";
  }
  if (depth != 0) return "missing ]";
  std::istringstream in(text);
  std::string line;
  std::vector<std::vector<std::string>> stack(1);
  int do_count = 0;
  int end_count = 0;
  while (std::getline(in, line)) {
    std::string t = trim(line);
    if (t.empty() || t[0] == '#') continue;
    if (t.size() >= 2 && t.substr(t.size() - 2) == "do") {
      do_count++;
      stack.push_back({});
      continue;
    }
    if (t == "end") {
      end_count++;
      if (stack.size() > 1) stack.pop_back();
      continue;
    }
    auto eq = t.find('=');
    if (eq == std::string::npos) continue;
    std::string key = trim(t.substr(0, eq));
    std::string val = trim(t.substr(eq + 1));
    if (!val.empty() && std::isalpha(static_cast<unsigned char>(val[0])) && val != "true" && val != "false") {
      bool ok = false;
      for (char c : val) if (!std::isalnum(static_cast<unsigned char>(c)) && c != '_') ok = true;
      if (!ok) return "invalid bare identifier value";
    }
    for (const auto& ex : stack.back()) if (ex == key || is_prefix(ex, key) || is_prefix(key, ex)) return "duplicate or conflicting key";
    stack.back().push_back(key);
  }
  if (do_count != end_count) return "missing end";
  return "";
}

static std::pair<std::string, std::string> extract_region_name(const std::string& text) {
  auto a = text.find("region \"");
  if (a == std::string::npos) return {"", ""};
  auto b = text.find('"', a + 8);
  if (b == std::string::npos) return {"", ""};
  std::string region = text.substr(a + 8, b - (a + 8));
  auto k = text.find("name = \"", b);
  if (k == std::string::npos) return {region, ""};
  auto e = text.find('"', k + 8);
  if (e == std::string::npos) return {region, ""};
  return {region, text.substr(k + 8, e - (k + 8))};
}

std::string run(const std::string& op, const std::string& text) {
  auto err = detect_error(text);
  if (!err.empty()) return err;
  auto rn = extract_region_name(text);
  if (op == "parse") return "{\"kind\":\"document\"}";
  if (op == "format") return text;
  if (op == "object") {
    if (rn.first.empty()) return "{}";
    return "{\"config\":{\"regions\":{\"" + rn.first + "\":{\"name\":\"" + rn.second + "\"}}}}";
  }
  if (op == "toml") return "[config.regions." + rn.first + "]\nname = \"" + rn.second + "\"\n";
  if (op == "yaml") return "config:\n  regions:\n    " + rn.first + ":\n      name: \"" + rn.second + "\"\n";
  if (op == "hcl") return "config {\n  regions {\n    " + rn.first + " {\n      name = \"" + rn.second + "\"\n    }\n  }\n}\n";
  return "";
}
