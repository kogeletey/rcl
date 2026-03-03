#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v crystal >/dev/null 2>&1; then
  echo "crystal is required for golden verification" >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

render_with_crystal() {
  local fmt="$1"
  local src="$2"
  crystal eval '
    require "./implementations/crystal/src/rcl"
    source = File.read(ARGV[1])
    doc = RCL.parse_string(source)
    case ARGV[0]
    when "json"
      print doc.to_h.to_json
    when "toml"
      print RCL.to_toml(doc)
    when "yml"
      print RCL.to_yaml(doc)
    when "hcl"
      print RCL.to_hcl(doc)
    when "rcl"
      print RCL.format(doc)
    else
      STDERR.puts "unsupported format: #{ARGV[0]}"
      exit 2
    end
  ' "$fmt" "$src"
}

compare_one() {
  local expected="$1"
  local fmt="$2"
  local src="$3"
  local actual="$TMP_DIR/actual.${fmt}"

  render_with_crystal "$fmt" "$src" > "$actual"

  if ! diff -u "$expected" "$actual"; then
    echo "Mismatch for $expected (source: $src)" >&2
    return 1
  fi
}

FAILED=0

while IFS= read -r rcl_file; do
  base="${rcl_file%.rcl}"
  for fmt in json toml yml hcl; do
    expected="${base}.${fmt}"
    if [ -f "$expected" ]; then
      if ! compare_one "$expected" "$fmt" "$rcl_file"; then
        FAILED=1
      fi
    fi
  done
done < <(find "$ROOT_DIR/e2e" -mindepth 2 -maxdepth 2 -type f -name '*.rcl' ! -path '*/cases/*' | sort)

if [ "$FAILED" -ne 0 ]; then
  echo "Golden verification failed." >&2
  exit 1
fi

echo "Golden verification passed."
