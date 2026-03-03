#!/usr/bin/env bash
set -euo pipefail

now_ms() {
  perl -MTime::HiRes=time -e 'printf("%.0f\n", time()*1000)'
}

measure_cmd_ms() {
  if [ "$#" -eq 0 ]; then
    echo "measure_cmd_ms requires a command" >&2
    return 2
  fi
  local start end
  start="$(now_ms)"
  "$@"
  end="$(now_ms)"
  echo $((end - start))
}
