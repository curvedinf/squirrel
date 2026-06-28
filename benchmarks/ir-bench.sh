#!/usr/bin/env bash
# Run callgrind on a single workload and print: workload, total Ir, checksum.
# Usage: ir-bench.sh <build_dir> <workload-spec...>
# Workload spec is a quoted string with filename + args, e.g. "registry_catalog.nut 500"
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:?build dir required}"; shift
runner="$build_dir/bin/sqbench"
out="${CALLGRIND_OUT:-/tmp/opencode/cg.out}"
label="${CALLGRIND_LABEL:-$(basename "$build_dir")}"
spec=("$@")
wl="${spec[0]}"
# callgrind: only instrument, run once. Ir totals are deterministic.
taskset -c 2 valgrind --tool=callgrind --callgrind-out-file="$out" \
    --separate-threads=no -q \
    "$runner" --compile-repeat 1 --run-repeat 3 \
    "$repo_root/benchmarks/workloads/$wl" "${spec[@]:1}" \
    > /tmp/opencode/cg_stdout.txt 2>&1 || { cat /tmp/opencode/cg_stdout.txt; exit 1; }
ir=$(callgrind_annotate --threshold=99 --auto=no "$out" 2>/dev/null \
     | awk '/PROGRAM TOTALS/{print $1; exit}')
ir=${ir%,}
cksum=$(grep -oE 'checksum=[0-9]+' /tmp/opencode/cg_stdout.txt | head -1 | cut -d= -f2)
printf '%s\t%s\t%s\t%s\n' "$label" "$(basename "$wl" .nut)" "$ir" "$cksum"
