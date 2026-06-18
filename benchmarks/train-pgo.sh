#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:-$repo_root/build-pgo}"
shift || true
extra_cmake_args=("$@")
profile_dir="$build_dir/pgo-data"
jobs="${JOBS:-$(nproc)}"
cpu_pin="${CPU_PIN:-0}"
train_compile_repeat="${TRAIN_COMPILE_REPEAT:-1}"
train_run_repeat="${TRAIN_RUN_REPEAT:-10}"

runner=("$build_dir/bin/sqbench")
if command -v taskset >/dev/null 2>&1 && [[ -n "$cpu_pin" ]]; then
  runner=(taskset -c "$cpu_pin" "${runner[@]}")
fi

cmake -S "$repo_root" -B "$build_dir" \
  -DSQ_BUILD_BENCHMARKS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DSQ_USE_FNO_SEMANTIC_INTERPOSITION=ON \
  -DSQ_PGO_MODE=GENERATE \
  "${extra_cmake_args[@]}"

rm -rf "$profile_dir"
mkdir -p "$profile_dir"

cmake --build "$build_dir" -j"$jobs" --target sqbench

"${runner[@]}" --compile-repeat "$train_compile_repeat" --run-repeat "$train_run_repeat" \
  "$repo_root/benchmarks/workloads/registry_catalog.nut" 180
"${runner[@]}" --compile-repeat "$train_compile_repeat" --run-repeat "$train_run_repeat" \
  "$repo_root/benchmarks/workloads/world_map_graph.nut" 30 18 12
"${runner[@]}" --compile-repeat "$train_compile_repeat" --run-repeat "$train_run_repeat" \
  "$repo_root/benchmarks/workloads/inventory_flow.nut" 3200 11

cmake -S "$repo_root" -B "$build_dir" \
  -DSQ_BUILD_BENCHMARKS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DSQ_USE_FNO_SEMANTIC_INTERPOSITION=ON \
  -DSQ_PGO_MODE=USE \
  "${extra_cmake_args[@]}"

cmake --build "$build_dir" -j"$jobs" --target sqbench
