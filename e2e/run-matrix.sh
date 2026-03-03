#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -n "${E2E_IMPL_LIST:-}" ]; then
  IFS=',' read -r -a REQUESTED_IMPLS <<< "$E2E_IMPL_LIST"
  if printf '%s\n' "${REQUESTED_IMPLS[@]}" | grep -qx "allavailable"; then
    mapfile -t ALL_IMPLS < <(find "$ROOT_DIR/implementations" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
    mapfile -t IMPLEMENTATIONS < <(printf '%s\n' "${ALL_IMPLS[@]}" "${REQUESTED_IMPLS[@]}" | awk 'NF' | grep -vx "allavailable" | sort -u)
  else
    IMPLEMENTATIONS=("${REQUESTED_IMPLS[@]}")
  fi
else
  mapfile -t IMPLEMENTATIONS < <(find "$ROOT_DIR/implementations" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
fi

if [ "${#IMPLEMENTATIONS[@]}" -eq 0 ]; then
  echo "No implementations selected"
  exit 0
fi

mkdir -p "$ROOT_DIR/e2e/perf"
for impl in "${IMPLEMENTATIONS[@]}"; do
  bash "$ROOT_DIR/e2e/run-implementation.sh" "$impl"
done

jq -s 'sort_by(.total_ms)' "$ROOT_DIR"/e2e/perf/*.json > "$ROOT_DIR/e2e/perf/summary.json"

echo "E2E Speed Summary"
echo "| implementation | total_ms | avg_ms | p95_ms |"
echo "|---|---:|---:|---:|"
jq -r '.[] | [.implementation, .total_ms, .avg_ms, .p95_ms] | "| \(.[0]) | \(.[1]) | \(.[2]) | \(.[3]) |"' "$ROOT_DIR/e2e/perf/summary.json"
