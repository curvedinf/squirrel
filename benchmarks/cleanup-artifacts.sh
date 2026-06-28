#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

keep=(
  build
  build-retained-source
  build-pgo-lto-gsp
  build-pgo-lto-fastdefaultget
)

keep_candidate="${1:-}"
if [[ -n "$keep_candidate" ]]; then
  keep+=("$keep_candidate")
fi

should_keep() {
  local path="$1"
  local name
  name=$(basename "$path")
  for keep_name in "${keep[@]}"; do
    if [[ "$name" == "$keep_name" ]]; then
      return 0
    fi
  done
  return 1
}

remove_path() {
  local path="$1"
  if [[ -d "$path" && ! -L "$path" ]]; then
    rm -rf -- "$path"
  elif [[ -e "$path" ]]; then
    rm -f -- "$path"
  fi
}

for path in build-* callgrind* perf.* a.out out.cnut; do
  [[ -e "$path" ]] || continue
  if should_keep "$path"; then
    continue
  fi
  remove_path "$path"
done

