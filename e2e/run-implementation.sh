#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/e2e/lib/measure.sh"

IMPL="${1:-}"
if [ -z "$IMPL" ]; then
  echo "usage: e2e/run-implementation.sh <implementation>" >&2
  exit 2
fi

if [ "$IMPL" = "allavailable" ]; then
  mapfile -t ALL_IMPLS < <(find "$ROOT_DIR/implementations" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  if [ "${#ALL_IMPLS[@]}" -eq 0 ]; then
    echo "No implementations available"
    exit 0
  fi
  for impl in "${ALL_IMPLS[@]}"; do
    bash "$ROOT_DIR/e2e/run-implementation.sh" "$impl"
  done
  exit 0
fi

run_impl_tests() {
  case "$IMPL" in
    c)
      (cd "$ROOT_DIR/implementations/c" && cc -std=c11 -Wall -Wextra -O2 rcl.c rcl_ast.c rcl_lexer.c rcl_parser.c rcl_parser_value.c rcl_project.c rcl_format.c rcl_convert.c test.c -o test_bin && ./test_bin)
      ;;
    cpp)
      (cd "$ROOT_DIR/implementations/cpp" && c++ -std=c++17 -Wall -Wextra -O2 rcl.cpp rcl_ast.cpp rcl_lexer.cpp rcl_parser.cpp rcl_project.cpp rcl_format.cpp rcl_convert.cpp test.cpp -o test_bin && ./test_bin)
      ;;
    crystal)
      (cd "$ROOT_DIR/implementations/crystal" && crystal spec)
      ;;
    csharp)
      (cd "$ROOT_DIR/implementations/csharp" && mcs -out:test_bin src/*.cs test/Test.cs && mono test_bin)
      ;;
    d)
      (cd "$ROOT_DIR/implementations/d" && ldc2 -i -Isource source/rcl/package.d test/test.d -of=test_bin && ./test_bin)
      ;;
    dart)
      (cd "$ROOT_DIR/implementations/dart" && dart pub get && dart test)
      ;;
    elixir)
      (cd "$ROOT_DIR/implementations/elixir" && elixir test/rcl_test.exs)
      ;;
    go)
      (cd "$ROOT_DIR/implementations/go" && go test ./...)
      ;;
    java)
      (cd "$ROOT_DIR/implementations/java" && mkdir -p out && javac -d out src/main/java/io/rcl/*.java src/test/java/io/rcl/RCLTest.java && java -cp out io.rcl.RCLTest)
      ;;
    julia)
      (cd "$ROOT_DIR/implementations/julia" && julia test/runtests.jl)
      ;;
    kotlin)
      (cd "$ROOT_DIR/implementations/kotlin" && mvn -B -ntp test)
      ;;
    lua)
      (cd "$ROOT_DIR/implementations/lua" && lua test.lua)
      ;;
    ocaml)
      (cd "$ROOT_DIR/implementations/ocaml" && opam exec -- ocamlc str.cma unix.cma rcl.ml test.ml -o test_bin && opam exec -- ./test_bin)
      ;;
    php)
      (cd "$ROOT_DIR/implementations/php" && php test/test.php)
      ;;
    ruby)
      (cd "$ROOT_DIR/implementations/ruby" && ruby -Ilib test/parser_test.rb)
      ;;
    rust)
      (cd "$ROOT_DIR/implementations/rust" && cargo test --all-targets)
      ;;
    swift)
      (cd "$ROOT_DIR/implementations/swift" && swift test)
      ;;
    typescript)
      (cd "$ROOT_DIR/implementations/typescript" && npm install && npm test)
      ;;
    zig)
      (cd "$ROOT_DIR/implementations/zig" && zig test rcl.zig)
      ;;
    *)
      echo "unsupported implementation: $IMPL" >&2
      return 2
      ;;
  esac
}

mkdir -p "$ROOT_DIR/e2e/perf"
DURATION_MS="$(measure_cmd_ms run_impl_tests)"

cat > "$ROOT_DIR/e2e/perf/${IMPL}.json" <<JSON
{"implementation":"$IMPL","total_ms":$DURATION_MS,"avg_ms":$DURATION_MS,"p95_ms":$DURATION_MS,"runs":1}
JSON

echo "[$IMPL] total=${DURATION_MS}ms avg=${DURATION_MS}ms p95=${DURATION_MS}ms"
