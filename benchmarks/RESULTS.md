# Benchmark Results Ledger

This file is the source of truth for benchmark baselines and experiment outcomes.

Policy:

- Keep the current retained-head baseline at the top of this file.
- Compare every new candidate against that retained-head baseline once.
- When a candidate is kept, promote its measured result to the new retained-head baseline here.
- Do not rerun older baselines unless we intentionally refresh the baseline set.

## Current Retained-Head Baseline

Use this for the next candidate unless a newer retained result is promoted.

Date: `2026-06-28`
Build: `./build-pgo-lto/bin/sqbench`
CPU pinning: `taskset -c 2`
Command set:

```bash
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/registry_catalog.nut 500
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/world_map_graph.nut 30 18 12
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/inventory_flow.nut 2200 11
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/session_context_flow.nut 450 12
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/scenario_tick_flow.nut 10200 24 14
taskset -c 2 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/volume_presence_scan.nut 650 6 12 6
```

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `46.535` | `2019808` |
| `world_map_graph` | `49.361` | `325170` |
| `inventory_flow` | `46.037` | `580946` |
| `session_context_flow` | `44.737` | `593415` |
| `scenario_tick_flow` | `50.074` | `2030324` |
| `volume_presence_scan` | `50.871` | `308206` |

This retained head adds ASCII-fast `string.tolower()` / `string.toupper()` mapping, unchanged-slice result reuse, and a prehashed `SQStringTable::AddWithHash()` path so changed case-map results do not recompute their interned-string hash on insertion. After six-workload source checksum smoke, direct plus compiled-bytecode string-case probes, two stock `samples/` interpreter runs, fresh PGO retraining, two clean sequential quiet-core control pairs against the prior retained worktree, and a final canonical `./build-pgo-lto/bin/sqbench` refresh, the authoritative six-workload retained baseline is `287.615 ms` total. Earlier baseline sections below are preserved for history.

## Historical Reference Baselines

### Immediate Prior Six-Workload Retained-Head Baseline

Date: `2026-06-28`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `47.387` | `2019808` |
| `world_map_graph` | `50.392` | `325170` |
| `inventory_flow` | `47.367` | `580946` |
| `session_context_flow` | `47.711` | `593415` |
| `scenario_tick_flow` | `52.132` | `2030324` |
| `volume_presence_scan` | `51.213` | `308206` |

This was the retained head before the ASCII-fast string-case mapping plus prehashed string-table insertion change was promoted. Its authoritative six-workload total was `296.202 ms`.

### Earlier Prior Six-Workload Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `50.345` | `2019808` |
| `world_map_graph` | `53.326` | `325170` |
| `inventory_flow` | `50.398` | `580946` |
| `session_context_flow` | `48.564` | `593415` |
| `scenario_tick_flow` | `52.663` | `2030324` |
| `volume_presence_scan` | `51.472` | `308206` |

This was the retained head before the thread-local small-block allocator cache was promoted. Its authoritative six-workload total was `306.768 ms`.

### Immediate Prior Three-Workload Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `17.984` | `727105` |
| `world_map_graph` | `52.483` | `325170` |
| `inventory_flow` | `74.219` | `812233` |

This was the last retained three-workload baseline before the suite was expanded to six workloads. It remains useful for history, but not for direct total-runtime comparisons against the expanded-suite baseline above.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `17.911` | `727105` |
| `world_map_graph` | `52.846` | `325170` |
| `inventory_flow` | `74.299` | `812233` |

This was the retained head before the non-empty table-literal spare-slot sizing change was promoted.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.331` | `727105` |
| `world_map_graph` | `52.681` | `325170` |
| `inventory_flow` | `75.520` | `812233` |

This was the retained head before the global `SQStringTable` load-factor growth change was promoted.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.690` | `727105` |
| `world_map_graph` | `52.478` | `325170` |
| `inventory_flow` | `76.664` | `812233` |

This was the retained head before the `SQVM::TryFastCallNative()` intrinsic result-path cleanup was promoted.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.804` | `727105` |
| `world_map_graph` | `52.961` | `325170` |
| `inventory_flow` | `76.832` | `812233` |

This was the retained head before the empty-string `SQVM::StringCat()` fast path was promoted.

### Earlier Prior Refreshed Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `19.633` | `727105` |
| `world_map_graph` | `54.329` | `325170` |
| `inventory_flow` | `79.579` | `812233` |

This was a fresh pinned rerun of the previously retained PGO+LTO head, taken to compare the bool/null cleanup fast-path candidate in the current machine state before promotion.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.586` | `727105` |
| `world_map_graph` | `52.975` | `325170` |
| `inventory_flow` | `81.885` | `812233` |

This was the frozen retained-head comparison target used for the string-key specialized direct-get experiment.

### Earlier Prior Refreshed Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.720` | `727105` |
| `world_map_graph` | `55.296` | `325170` |
| `inventory_flow` | `82.709` | `812233` |

This was a fresh pinned rerun of the previously retained PGO+LTO head, taken to compare the next source-level candidate in the current machine state before promotion.

### Earlier Prior PGO Retained-Head Baseline

Date: `2026-06-18`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `19.681` | `727105` |
| `world_map_graph` | `52.719` | `325170` |
| `inventory_flow` | `78.413` | `812233` |

This was the previously retained PGO+LTO head. It later became the source head that was refreshed on `2026-06-27` for the next retained comparison.

### Earlier Prior Retained-Head Baseline

Date: `2026-06-18`
Build: `./build-pgo-retained/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `19.214` | `727105` |
| `world_map_graph` | `54.951` | `325170` |
| `inventory_flow` | `80.224` | `812233` |

This was the retained fresh pinned PGO build. It became the frozen comparison target for the PGO+LTO re-evaluation.

### Earlier Prior Source Retained-Head Baseline

Date: `2026-06-18`
Build: `./build/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `22.230` | `727105` |
| `world_map_graph` | `63.186` | `325170` |
| `inventory_flow` | `95.078` | `812233` |

This was the retained GCC `-fno-semantic-interposition` build. It became the frozen comparison target for the fresh retained PGO retrain.

### Earlier Prior Retained Source Baseline

Date: `2026-06-18`
Build: `./build/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `23.116` | `727105` |
| `world_map_graph` | `65.424` | `325170` |
| `inventory_flow` | `106.310` | `812233` |

This was the retained direct-stack `string.find()` source head. It became the frozen comparison target for the `-fno-semantic-interposition` re-evaluation.

### Earlier Refreshed Prior Retained-Head Baseline

Date: `2026-06-18`
Build: `./build/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `23.102` | `727105` |
| `world_map_graph` | `67.010` | `325170` |
| `inventory_flow` | `108.144` | `812233` |

This was an intentional refreshed measurement of the retained direct-hit `_OP_GETK` / `_OP_PREPCALLK` source head, taken after later candidate runs stopped matching the earlier machine-state baseline closely enough to compare fairly. It was used as the frozen comparison target for the direct-stack `string.find()` re-evaluation.

### Earlier Measurement Of That Prior Retained Source Head

Date: `2026-06-18`
Build: `./build/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `23.058` | `727105` |
| `world_map_graph` | `64.900` | `325170` |
| `inventory_flow` | `103.424` | `812233` |

This earlier measurement came from retaining direct-hit bypasses for `_OP_GETK` / `_OP_PREPCALLK` on `table` / `class` / `instance` member hits over the prior retained-head baseline of `24.081 / 65.150 / 105.887 ms`, which was a `+1.915%` overall improvement. It is preserved here for history, but later retries should compare against the refreshed baseline above when machine state drifts.

### Older Retained-Head Baseline

Date: `2026-06-18`
Build: `./build/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `24.081` | `727105` |
| `world_map_graph` | `65.150` | `325170` |
| `inventory_flow` | `105.887` | `812233` |

### Historical Stock Reference

This is a frozen earlier stock measurement. Keep it as a rough reference only; do not use it for per-candidate comparisons unless stock is rerun in the same machine state.

| Workload | run_avg_ms |
| --- | ---: |
| `registry_catalog` | `26.893` |
| `world_map_graph` | `77.760` |
| `inventory_flow` | `136.312` |

## Retained Results

### Historical retained wins from earlier passes

Some earlier runs were kept before this ledger existed. Where exact per-workload numbers were preserved, they are listed below. Where only the aggregate outcome survived, that is recorded directly.

| Change | Baseline used | Result | Overall |
| --- | --- | --- | ---: |
| ASCII-fast `string.tolower()` / `string.toupper()` mapping with unchanged-slice reuse and prehashed string-table insertion | retained PGO+LTO head `47.387 / 50.392 / 47.367 / 47.711 / 52.132 / 51.213 ms` | clean retry after fresh PGO+LTO retrains: candidate `46.364 / 49.291 / 46.102 / 45.178 / 50.649 / 52.950 ms` versus live control `47.293 / 50.745 / 48.385 / 47.481 / 51.674 / 50.882 ms` (`+1.998%` by total); reverse-order confirmation stayed ahead at `47.256 / 49.563 / 46.086 / 44.357 / 50.463 / 53.384 ms` versus live control `47.886 / 50.933 / 49.038 / 47.770 / 51.898 / 51.205 ms` (`+2.551%` by total); the final canonical `./build-pgo-lto/bin/sqbench` refresh settled at `46.535 / 49.361 / 46.037 / 44.737 / 50.074 / 50.871 ms` | `+2.899%` |
| Bounded thread-local small-block cache under `sq_vm_malloc()` / `sq_vm_realloc()` / `sq_vm_free()` | retained PGO+LTO head `50.345 / 53.326 / 50.398 / 48.564 / 52.663 / 51.472 ms` | six-workload checksum smoke, `samples/class.nut`, `samples/generators.nut`, fresh PGO+LTO retraining, and two clean sequential quiet-core control pairs promoted `47.387 / 50.392 / 47.367 / 47.711 / 52.132 / 51.213 ms` | `+3.444%` |
| `_OP_CAT3` peephole for three-part string-concat chains when the first binary `+` is provably string-producing | retained PGO+LTO head `17.984 / 52.483 / 74.219 ms` | clean retry: `18.307 / 51.626 / 73.828 ms` (`+0.639%` by total); confirmation promoted: `18.466 / 51.954 / 73.821 ms` | `+0.308%` |
| Leave one spare initial slot for non-empty table literals when emitting `_OP_NEWOBJ` capacities | retained PGO+LTO head `17.911 / 52.846 / 74.299 ms` | clean retry: `18.134 / 52.244 / 74.191 ms` (`+0.336%` by total); confirmation promoted: `17.984 / 52.483 / 74.219 ms` | `+0.255%` |
| Grow the global `SQStringTable` before `Concat()` / `Add()` insertions once it reaches a 75% load factor | retained PGO+LTO head `18.331 / 52.681 / 75.520 ms` | clean retry: `18.089 / 53.498 / 74.630 ms` (`+0.215%` by total); confirmation promoted: `17.911 / 52.846 / 74.299 ms` | `+1.007%` |
| Direct-result string conversions and primitive `tostring()` fast paths in `SQVM::TryFastCallNative()` | retained PGO+LTO head `18.690 / 52.478 / 76.664 ms` | clean retry: `18.729 / 52.893 / 75.289 ms`; confirmation promoted: `18.331 / 52.681 / 75.520 ms` | `+0.879%` |
| Empty-string fast paths in `SQVM::StringCat()` | retained PGO+LTO head `18.804 / 52.961 / 76.832 ms` | clean retry: `18.624 / 52.597 / 76.493 ms`; confirmation promoted: `18.690 / 52.478 / 76.664 ms` | `+0.515%` |
| Same-value fast paths in `SQObjectPtr::operator=(bool)` and `SQObjectPtr::Null()` | refreshed retained PGO+LTO head `19.633 / 54.329 / 79.579 ms` | clean retry: `19.100 / 54.267 / 78.035 ms` (`+1.393%`); confirmation promoted: `18.804 / 52.961 / 76.832 ms` | `+3.220%` |
| Full-hash guard before `memcmp()` in `SQStringTable::Concat()` / `Add()` | refreshed retained PGO+LTO head `18.994 / 54.189 / 80.237 ms` | clean retry: `19.085 / 53.473 / 77.881 ms` (`+1.943%`); confirmation promoted: `19.302 / 53.996 / 79.207 ms` | `+0.596%` |
| Interned string-key specialized direct get paths for `table` / `class` / `instance` lookups and default delegates | retained PGO+LTO head `18.586 / 52.975 / 81.885 ms` | clean retry: `18.471 / 53.055 / 78.777 ms` (`+2.048%`); confirmation promoted: `18.672 / 52.394 / 78.479 ms` | `+2.542%` |
| Reused comparator call-frame slots across `array.sort()` callback invocations | refreshed retained PGO+LTO head `18.720 / 55.296 / 82.709 ms` | clean retry: `18.754 / 52.903 / 82.111 ms` (`+1.887%`); confirmation promoted: `18.586 / 52.975 / 81.885 ms` | `+2.092%` |
| `_OP_EXISTS` fast path | earlier retained source head | exact absolute timings not preserved in this ledger | `+1.761%` |
| `array.sort` comparator-call rewrite | earlier retained source / PGO heads | exact absolute timings not preserved in this ledger | `+2.834%` source, `+0.304%` PGO |
| `array.sort` zero-based heap fix | earlier retained source / PGO heads | exact absolute timings not preserved in this ledger | `+7.185%` source, `+6.566%` PGO |
| `ToString` small-int / bool / null cache | earlier retained source / PGO heads | exact absolute timings not preserved in this ledger | `+2.612%` source, `+2.151%` PGO |
| `StringCat()` skips redundant `ToString()` when an operand is already a string | `24.904 / 68.418 / 117.122 ms` | `24.631 / 68.296 / 108.588 ms` | `+4.243%` |
| `TypeOf()` returns already-interned built-in type strings directly | `24.631 / 68.296 / 108.588 ms` | `23.849 / 66.202 / 108.436 ms` | `+1.503%` |
| `SQTable::_Get()` hoists searched key raw/type out of the bucket walk | `24.489 / 66.827 / 108.657 ms` | `23.708 / 65.444 / 107.847 ms` | `+1.487%` |
| `string.slice` intrinsic fast path | `23.708 / 65.444 / 107.847 ms` | `24.081 / 65.150 / 105.887 ms` | `+0.955%` |
| Direct-hit `_OP_GETK` / `_OP_PREPCALLK` bypass for `table` / `class` / `instance` member hits | `24.081 / 65.150 / 105.887 ms` | `23.058 / 64.900 / 103.424 ms` | `+1.915%` |
| Direct-stack `string.find()` rewrite | mixed earlier tries vs `23.708 / 65.444 / 107.847 ms`, then refreshed baseline `23.102 / 67.010 / 108.144 ms` | earlier mixed tries: `24.040 / 66.677 / 105.559 ms` (`+0.367%`), `24.253 / 68.315 / 108.869 ms` (`-1.237%`); refreshed retry 1: `23.210 / 64.614 / 106.890 ms`; confirmation promoted: `23.116 / 65.424 / 106.310 ms` | `+1.718%` |
| GCC `-fno-semantic-interposition` on non-Debug builds | `23.116 / 65.424 / 106.310 ms` | separate build tries: `21.528 / 63.735 / 95.338 ms` (`+7.313%`), `22.370 / 62.149 / 100.535 ms` (`+5.027%`); main retained build run 1: `22.015 / 67.108 / 94.855 ms` (`+5.580%`); confirmation promoted: `22.230 / 63.186 / 95.078 ms` | `+7.368%` |
| Fresh pinned PGO retrain on the retained `-fno-semantic-interposition` head | `22.230 / 63.186 / 95.078 ms` | clean retry after updating `train-pgo.sh` to pin training and force retained flags: `19.267 / 56.820 / 84.957 ms` (`+10.776%`); confirmation promoted: `19.214 / 54.951 / 80.224 ms` | `+14.463%` |
| PGO+LTO build on top of the retained PGO `-fno-semantic-interposition` head | `19.214 / 54.951 / 80.224 ms` | clean retry 1: `18.713 / 52.451 / 78.883 ms` (`+2.812%`); clean retry 2: `18.699 / 52.680 / 82.407 ms` (`+0.391%`); tie-break promoted: `19.681 / 52.719 / 78.413 ms` | `+2.316%` |

### Historical retained PGO snapshot

This older retained PGO snapshot predates the retained `-fno-semantic-interposition` head. It is preserved for history only; the current retained-head baseline above supersedes it.

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `22.111` | `727105` |
| `world_map_graph` | `61.608` | `325170` |
| `inventory_flow` | `95.670` | `812233` |

## Rolled Back Results

These candidates were benchmark-negative or otherwise not retained.

### Re-evaluated against retained six-workload head `50.345 / 53.326 / 50.398 / 48.564 / 52.663 / 51.472 ms`

These retries were run after the retained head and PGO training mix were both refreshed to the six-workload suite.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Intrinsic fast path for `string.tolower()` / `string.toupper()` default-delegate calls | `50.345 / 53.326 / 50.398 / 48.564 / 52.663 / 51.472 ms` | direct and compiled-bytecode string-case probes matched on full-range, sliced, and error-path behavior; the first pinned PGO+LTO retry landed at `50.346 / 52.971 / 48.912 / 49.016 / 52.792 / 51.800 ms` (`+0.304%` by total), but the confirmation slipped to `51.247 / 55.109 / 51.160 / 50.458 / 53.601 / 52.719 ms` (`-2.452%` by total) and the tie-break still landed at `51.708 / 53.929 / 50.727 / 50.462 / 52.133 / 52.850 ms` (`-1.643%` by total) | rolled back; not stable enough to retain |
| Return the original string from `string.tolower()` / `string.toupper()` when the selected slice is already unchanged | `50.345 / 53.326 / 50.398 / 48.564 / 52.663 / 51.472 ms` | source-smoke checksums stayed clean and direct plus compiled-bytecode string-case probes still matched on full-range, sliced, and error-path behavior, but the authoritative pinned PGO+LTO retry landed at `51.023 / 61.337 / 49.987 / 45.696 / 53.009 / 51.556 ms` (`-1.904%` by total) with a large `world_map_graph` regression | rolled back |
| ASCII-fast plus intrinsic `string.tolower()` / `string.toupper()` with lazy allocation and no-op result reuse | `50.345 / 53.326 / 50.398 / 48.564 / 52.663 / 51.472 ms` | six-workload source smoke stayed checksum-clean, and direct plus compiled-bytecode string-case probes still matched on full-range, sliced, no-op, and error-path behavior. An initial pinned run was invalidated by seven orphaned `inferno -benchmark` processes saturating the host. After clearing that interference, a fair quiet-core control run on the retained worktree measured `49.193 / 52.320 / 47.907 / 49.050 / 51.324 / 52.305 ms`, while the candidate measured `49.314 / 52.441 / 50.331 / 49.573 / 50.306 / 51.640 ms` (`-0.498%` by total) | rolled back |

### Re-evaluated against retained head `18.466 / 51.954 / 73.821 ms`

These retries were run after retaining the `_OP_CAT3` three-part string-concat chain change.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Skip `TryFastCallNative()` entirely for non-intrinsic native closures with `SQ_NCI_NONE` | `18.466 / 51.954 / 73.821 ms` | rejected during smoke before a pinned run: source smoke was `22.256 / 65.581 / 91.678 ms` with matching checksums, which lost clear ground on `registry_catalog` and `world_map_graph` versus the retained source behavior | rolled back |
| Raise comparator-driven `array.sort()` small-array insertion cutoff to 48 elements before quicksort | `18.466 / 51.954 / 73.821 ms` | rejected during smoke before a pinned run: source smoke was `22.012 / 62.812 / 97.662 ms` with matching checksums, targeted sort behavior stayed correct across 48/49-element callback sorts plus resize-during-compare failure, but `inventory_flow` regressed too hard to justify a pinned run | rolled back |
| Direct type-dispatch for `array.sort()` comparator return values instead of generic numeric/bool conversion helpers | `18.466 / 51.954 / 73.821 ms` | rejected during smoke before a pinned run: source smoke was `24.311 / 67.471 / 100.603 ms` with matching checksums, targeted sort behavior stayed correct for integer, float, bool, and resize-during-compare cases, but the broad workload picture was clearly negative before a pinned retry | rolled back |

### Re-evaluated against retained head `17.984 / 52.483 / 74.219 ms`

These retries were run after retaining the non-empty table-literal spare-slot sizing change.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Direct type-dispatch for `array.sort()` comparator return values instead of generic numeric/bool conversion helpers | `17.984 / 52.483 / 74.219 ms` | source smoke was `23.548 / 66.803 / 98.302 ms` with matching checksums, targeted sort behavior stayed correct for integer, float, bool, and resize-during-compare cases, but the authoritative pinned PGO+LTO retry landed at `18.010 / 52.805 / 74.096 ms` (`-0.156%` by total) | rolled back |
| Literal-folded `_OP_ADDK` peephole to skip loading right-hand constants before `_OP_ADD` | `17.984 / 52.483 / 74.219 ms` | source smoke was `22.061 / 64.148 / 92.537 ms` with matching checksums, direct and bytecode execution matched for string and numeric literal-add probes, but the authoritative pinned PGO+LTO retry landed at `18.097 / 52.425 / 75.927 ms` (`-1.218%` by total) | rolled back |

### Re-evaluated against retained head `17.911 / 52.846 / 74.299 ms`

These retries were run after retaining the earlier-growth `SQStringTable` load-factor change.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Non-recursive root-table fallback shortcut in `SQVM::Get()` when the closure root is a plain table with no delegate | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.524 / 53.900 / 74.959 ms` (`-1.604%` by total) | rolled back |
| Scalar fast path in `SQObjectPtr` copy assignment for non-refcounted values | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.086 / 53.165 / 74.911 ms` (`-0.762%` by total) | rolled back |
| Grow `SQTable` before `NewSlot()` insertions once it reaches a 75% load factor | `17.911 / 52.846 / 74.299 ms` | rejected during smoke before a pinned run: `registry_catalog` checksum still matched at `24.486 ms`, `world_map_graph` checksum still matched at `63.836 ms`, but `inventory_flow` changed from `812233` to `812226` at `91.862 ms` | rolled back; invalid semantics |
| Same-scalar-type fast path in `SQObjectPtr` assignment for `integer` / `float` / `userpointer` / `bool` | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.426 / 55.278 / 74.914 ms` (`-2.456%` by total) | rolled back |
| `_Swap()` the displaced `SQTable::NewSlot()` collision node into the free slot instead of copy-plus-`Null()` | `17.911 / 52.846 / 74.299 ms` | clean retry: `17.914 / 63.396 / 74.785 ms` (`-7.610%` by total) | rolled back |
| `SQDelegable::GetMetaMethod()` via `SQTable::GetStr()` for interned metamethod keys | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.876 / 53.788 / 74.306 ms` (`-1.319%` by total) | rolled back |
| Non-owning delegate-table object views in delegated `Get` / `Set` fallbacks | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.303 / 64.865 / 76.134 ms` (`-9.821%` by total) | rolled back |
| Checked intrinsic fast-call helper reused by cached `_OP_PREPCALLK` default-delegate native calls | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.326 / 54.206 / 75.757 ms` (`-2.229%` by total) | rolled back |
| Raw-pointer-first interned-string comparison in `SQTable::_GetStr()` | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.769 / 54.990 / 77.281 ms` (`-4.125%` by total) | rolled back |
| Length-gated fast delegate-key decoding with reused string pointers in cached/default delegate lookups | `17.911 / 52.846 / 74.299 ms` | clean retry: `18.502 / 54.141 / 76.144 ms` (`-2.572%` by total) | rolled back |
| Literal-key peephole opcodes for `_OP_NEWSLOT` / `_OP_NEWSLOTA` to skip VM key loads | `17.911 / 52.846 / 74.299 ms` | source smoke beat the restored retained source head at `24.263 / 68.760 / 104.267 ms` vs `23.433 / 69.900 / 110.873 ms`, but the authoritative pinned PGO+LTO retry landed at `19.982 / 58.904 / 85.504 ms` (`-13.329%` by total) | rolled back |
| Ownership-transfer `SQObjectPtr::MoveFrom()` in `CloseOuters()`, vararg packing, and generator resume | `17.911 / 52.846 / 74.299 ms` | source smoke improved to `21.923 / 62.665 / 91.799 ms` with matching checksums, but the authoritative pinned PGO+LTO retry landed at `17.831 / 52.733 / 75.015 ms` (`-0.361%` by total) | rolled back; `inventory_flow` regressed to `75.015 ms` despite matching checksums |
| Precomputed `SQFunctionProto` flag to skip `CloseOuters()` for frames that cannot create captured locals | `17.911 / 52.846 / 74.299 ms` | source smoke improved to `21.869 / 64.223 / 93.731 ms` with matching checksums, but the authoritative pinned PGO+LTO retry landed at `18.248 / 54.769 / 76.363 ms` (`-2.981%` by total) | rolled back |
| Decimal-prefix fast path in duplicated string-to-number helpers for base-10 `tointeger()` / `tofloat()` conversions | `17.911 / 52.846 / 74.299 ms` | source smoke stayed checksum-clean at `23.410 / 68.283 / 100.026 ms`, targeted conversion outputs matched the retained binary on decimal / exponent / overflow edge cases, but the authoritative pinned PGO+LTO retry landed at `18.223 / 52.928 / 75.388 ms` (`-1.022%` by total) | rolled back |
| Tiny raw-pointer cache for repeated interned string-pair concatenations in `SQStringTable::Concat()` | `17.911 / 52.846 / 74.299 ms` | source smoke improved to `21.958 / 63.415 / 96.722 ms` with matching checksums, a targeted concat/lifetime script matched the retained binary output, but the authoritative pinned PGO+LTO retry landed at `18.666 / 53.775 / 76.744 ms` (`-2.846%` by total) | rolled back |
| Hoist comparator resize-guard baseline out of each `_sort_compare()` callback in `array.sort()` | `17.911 / 52.846 / 74.299 ms` | source smoke improved to `21.664 / 60.832 / 92.575 ms` with matching checksums and targeted sort behavior stayed correct, but the authoritative pinned PGO+LTO retry was only `17.875 / 52.586 / 74.498 ms` (`+0.067%` by total) and the confirmation run fell to `18.249 / 52.843 / 75.623 ms` (`-1.144%` by total) | rolled back; not stable enough to retain |
| Single-character fast path in `string_find()` before `scstrstr()` | `17.911 / 52.846 / 74.299 ms` | source smoke was `24.303 / 68.730 / 104.961 ms` with matching checksums, targeted `string.find()` behavior stayed correct for single-char, empty-substring, out-of-range, and invalid-param cases, but the authoritative pinned PGO+LTO retry landed at `17.742 / 53.657 / 75.175 ms` (`-1.047%` by total) | rolled back |

### Re-evaluated against retained head `18.331 / 52.681 / 75.520 ms`

These retries were run after retaining direct-result intrinsic conversions and primitive `tostring()` fast paths in `SQVM::TryFastCallNative()`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Known-null `SQObjectPtr` assignment helper for fresh `SQTable::NewSlot()` destinations | `18.331 / 52.681 / 75.520 ms` | initial retry: `17.765 / 53.610 / 74.488 ms` (`+0.459%` by total); confirmation retry: `17.697 / 54.379 / 75.385 ms` (`-0.630%` by total) | rolled back; confirmation lost on `world_map_graph` and total runtime |
| Shared `_OP_PREPCALLK` next-call decoding and fast-path branch consolidation in `SQVM::Execute()` | `18.331 / 52.681 / 75.520 ms` | initial retry: `18.218 / 52.129 / 74.942 ms` (`+0.856%` by total); confirmation retry: `17.996 / 53.455 / 75.454 ms` (`-0.254%` by total) | rolled back; confirmation lost on `world_map_graph` and `inventory_flow` |
| Detached-free bitmap tracking for `SQTable::NewSlot()` free-slot selection | `18.331 / 52.681 / 75.520 ms` | rejected during smoke before a pinned run: `registry_catalog` checksum still matched at `20.772 ms`, `world_map_graph` checksum still matched at `60.624 ms`, but `inventory_flow` did not finish within a `30 s` timeout | rolled back; pathological slowdown on `inventory_flow` |

### Re-evaluated against retained head `18.804 / 52.961 / 76.832 ms`

These retries were run after retaining same-value fast paths in `SQObjectPtr::operator=(bool)` and `SQObjectPtr::Null()`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Skip `CloseOuters()` when the head open outer is already below the closing boundary | `18.804 / 52.961 / 76.832 ms` | clean retry: `18.500 / 53.249 / 78.749 ms` (`-1.279%` by total) | rolled back |
| Binary insertion search for comparator-driven `array.sort()` small partitions | `18.804 / 52.961 / 76.832 ms` | clean retry: `19.105 / 54.901 / 77.814 ms` (`-2.169%` by total) | rolled back |
| String-key specialized `SQTable::Get()` / `Set()` / `NewSlot()` / `Remove()` / `Exists()` | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.340 / 52.594 / 75.836 ms` (`+1.229%` by total); post-contention rerun after an unrelated external link finished: `18.640 / 53.834 / 76.929 ms` (`-0.542%` by total) | rolled back; not stable enough to promote |
| Remove redundant `_delegate` branches around `GetMetaMethod()` and use existence-only lookup in table `newslot` | `18.804 / 52.961 / 76.832 ms` | clean retry: `20.176 / 55.567 / 90.065 ms` (`-11.582%` by total) | rolled back |
| Specialized `SQTable::Rehash()` reinsertion helper to bypass duplicate-checking `NewSlot()` work | `18.804 / 52.961 / 76.832 ms` | clean retry: `18.489 / 55.924 / 77.980 ms` (`-2.555%` by total) | rolled back |
| Same-value fast path in generic `SQObjectPtr` copy assignment | `18.804 / 52.961 / 76.832 ms` | clean retry: `19.151 / 54.260 / 78.521 ms` (`-2.244%` by total) | rolled back |
| Split-loop `_hashstr2()` rewrite for concatenated string hashing in `SQStringTable::Concat()` | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.554 / 51.927 / 76.638 ms` (`+0.995%` by total); confirmation retry: `19.077 / 52.633 / 77.545 ms` (`-0.443%` by total) | rolled back; not stable enough to promote |
| Short-suffix fast path in `_hashstr2()` for concatenations where the second operand contributes only one sampled byte | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.272 / 52.200 / 76.933 ms` (`+0.802%` by total); follow-up registry rerun stayed positive at `18.241 ms`, but `world_map_graph` diverged to `63.132 ms`, and a dedicated world-only rerun still came back at `55.018 ms` vs the `52.961 ms` baseline | rolled back; `world_map_graph` not stable enough to promote |
| String-key-specialized `SQVM::Get()` / default-delegate helpers with reused root-fallback `strkey` | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.348 / 52.420 / 76.383 ms` (`+0.973%` by total); confirmation retry: `18.658 / 53.280 / 78.396 ms` (`-1.169%` by total) | rolled back; not stable enough to promote |
| Extended cached delegate-method fast path to array/string `push` / `append` / `slice` / `find` with length-based key dispatch | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.819 / 52.818 / 77.097 ms` (`-0.092%` by total); follow-up registry rerun was `18.774 ms`, but `world_map_graph` degraded to `55.556 ms` on confirmation | rolled back; not stable enough to promote |
| Direct stdlib `array_append()` implementation instead of routing through `sq_arrayappend()` | `18.804 / 52.961 / 76.832 ms` | clean retry: `18.229 / 52.910 / 80.653 ms` (`-2.150%` by total) | rolled back |
| Inline the initial 4 `SQTable` hash nodes into the table object to avoid a second allocation for small tables | `18.804 / 52.961 / 76.832 ms` | rejected during the PGO training harness before an authoritative pinned run: `registry_catalog` and `world_map_graph` checksums still matched, but `inventory_flow` changed from `812233` to `808510` | rolled back; invalid semantics |
| State-local cache for recycled 4-node `SQTable` hash blocks | `18.804 / 52.961 / 76.832 ms` | rejected during the pinned PGO training harness before an authoritative pinned run: `registry_catalog` crashed with `Segmentation fault (core dumped)` | rolled back; invalid semantics |
| Short-vector fast path for `CallNative()` typemask validation | `18.804 / 52.961 / 76.832 ms` | clean retry: `18.583 / 54.308 / 79.132 ms` (`-2.306%` by total) | rolled back |
| Skip repeated direct table/class/instance lookup in `Get()` after a `_OP_GETK` / `_OP_PREPCALLK` direct miss | `18.804 / 52.961 / 76.832 ms` | clean retry: `18.674 / 53.405 / 78.564 ms` (`-1.377%` by total) | rolled back |
| Bypass `TranslateIndex()` in `array` / `string` / `table` `Next()` iteration | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.468 / 53.054 / 76.916 ms` (`+0.107%` by total); confirmation retry: `18.836 / 54.375 / 77.671 ms` (`-1.538%` by total) | rolled back; not stable enough to promote |
| Move return values directly out of callee/native frame slots when no open outer captures the source slot | `18.804 / 52.961 / 76.832 ms` | initial retry: `18.427 / 52.708 / 76.433 ms` (`+0.692%` by total); confirmation retry: `18.357 / 52.859 / 77.361 ms` (`+0.013%` by total); tie-break retry: `18.675 / 53.142 / 76.973 ms` (`-0.130%` by total) | rolled back; not stable enough to promote |
| Direct pointer access to member-table values for class / instance `Get*` / `Set` / attribute lookup | `18.804 / 52.961 / 76.832 ms` | clean retry: `19.036 / 52.531 / 85.431 ms` (`-5.653%` by total) | rolled back |

### Re-evaluated against retained head `18.690 / 52.478 / 76.664 ms`

These retries were run after retaining empty-string fast paths in `SQVM::StringCat()`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Closure-specific `CallInfo::_closure` set/clear helpers for frame entry, teardown, and generator resume | `18.690 / 52.478 / 76.664 ms` | clean retry: `18.594 / 53.023 / 76.151 ms` (`+0.043%` by total; `world_map_graph` `-1.039%`) | rolled back; effectively neutral overall and regressed `world_map_graph` |
| Move native return values out of native frame slots with `_Swap()` before `LeaveFrame()` | `18.690 / 52.478 / 76.664 ms` | clean retry: `18.331 / 53.145 / 76.888 ms` (`-0.360%` by total; `registry_catalog` `+1.921%`, `world_map_graph` `-1.271%`, `inventory_flow` `-0.292%`) | rolled back |
| Reuse `Get()`'s string-key knowledge and cached fast-delegate key in `InvokeDefaultDelegate()` | `18.690 / 52.478 / 76.664 ms` | initial retry: `18.442 / 52.529 / 76.644 ms` (`+0.147%` by total); confirmation retry: `18.365 / 52.892 / 76.648 ms` (`-0.049%` by total) | rolled back; not stable enough to promote |

### Re-evaluated against retained head `18.994 / 54.189 / 80.237 ms`

These retries were run after refreshing the retained PGO+LTO baseline in the current machine state and before retaining the full-hash guard in `SQStringTable`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Same-value fast path in `SQObjectPtr` copy assignment | `18.994 / 54.189 / 80.237 ms` | clean retry: `19.778 / 54.656 / 83.040 ms` (`-2.642%` by total) | rolled back |

### Re-evaluated against retained head `18.586 / 52.975 / 81.885 ms`

These retries were run after retaining reusable comparator call-frame slots in `array.sort()`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Small-string exact-length freelist cache in `SQStringTable` | `18.586 / 52.975 / 81.885 ms` | clean retry: `19.369 / 65.549 / 132.573 ms` with matching checksums (`-41.736%` by total) | rolled back; clear regression |

### Re-evaluated against retained head `19.681 / 52.719 / 78.413 ms`

These retries were run after retaining the PGO+LTO build.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| `-march=native -mtune=native` layered on top of the retained PGO+LTO build | `19.681 / 52.719 / 78.413 ms` | clean retry: `18.954 / 53.256 / 79.357 ms` (`-0.500%` by total) | rolled back |
| Heavier pinned PGO+LTO retrain with `TRAIN_RUN_REPEAT=20` | `19.681 / 52.719 / 78.413 ms` | clean retry: `36.428 / 54.091 / 81.223 ms` (`-13.877%` by total) | rolled back |
| `-fno-plt` layered on top of the retained PGO+LTO build | `19.681 / 52.719 / 78.413 ms` | clean retry: `18.571 / 53.515 / 79.069 ms` (`-0.227%` by total) | rolled back |

### Rejected before full benchmark on retained head `19.214 / 54.951 / 80.224 ms`

These were tried after promoting the fresh retained PGO head, but they failed smoke validation before a full PGO comparison run.

| Change | Validation result | Outcome |
| --- | --- | --- |
| Empty-main-bucket fast path in `SQTable::NewSlot()` | initial smoke failed with runtime errors (`the index 'len' does not exist` in `registry_catalog`, `null cannot be used as index` in `world_map_graph`); after fixing the exhausted-`_firstfree` case, `registry_catalog` and `world_map_graph` matched but `inventory_flow` checksum became `812230` instead of `812233` | rolled back; invalid semantics |

### Re-evaluated against retained head `19.214 / 54.951 / 80.224 ms`

These retries were run after promoting the fresh retained PGO head.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Early intrinsic fast path in `CallNative()` before the generic type-mask walk for `len`, `tofloat`, `tostring`, and numeric-base `tointeger` | `19.214 / 54.951 / 80.224 ms` | clean retry: `29.652 / 55.675 / 83.999 ms` (`-9.675%` by total) | rolled back |

### Re-evaluated against retained head `22.230 / 63.186 / 95.078 ms`

These retries were run after retaining GCC `-fno-semantic-interposition`.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Direct stack/top access in `get_slice_params()` with direct string/array length reads | `22.230 / 63.186 / 95.078 ms` | clean retry 1: `22.033 / 62.876 / 94.790 ms` (`+0.440%` by total), clean retry 2: `21.917 / 64.229 / 102.862 ms` (`-4.717%` by total) | rolled back; unstable |
| `-march=native -mtune=native` build on top of the retained `-fno-semantic-interposition` head | `22.230 / 63.186 / 95.078 ms` | manual-flag rebuild run 1: `22.128 / 61.380 / 94.317 ms` (`+1.479%` by total), manual-flag rebuild run 2: `21.551 / 62.171 / 92.290 ms` (`+2.483%` by total); optionized rebuild run 1: `22.473 / 63.054 / 98.455 ms` (`-1.932%` by total), optionized rebuild run 2: `21.409 / 62.484 / 94.602 ms` (`+1.108%` by total) | not promoted; inconsistent across clean reruns |
| LTO / interprocedural build on top of the retained `-fno-semantic-interposition` head | `22.230 / 63.186 / 95.078 ms` | clean retry: `22.745 / 64.511 / 100.017 ms` (`-3.756%` by total) | rolled back |

### PGO refresh attempts on the current retained source head

These older failed PGO retrains predate the retained `-fno-semantic-interposition` build flag and are preserved only for history. The fresh retained PGO result above supersedes them.

| Change | Comparison reference | Retry results | Outcome |
| --- | --- | --- | --- |
| Refreshed PGO retrain on current retained head using the existing unpinned training script | source head `23.116 / 65.424 / 106.310 ms`, retained PGO `22.111 / 61.608 / 95.670 ms` | clean run 1: `23.155 / 77.832 / 96.591 ms` (`-1.400%` vs source, `-10.139%` vs retained PGO); clean run 2 confirmation: `22.653 / 78.299 / 127.146 ms` (`-17.063%` vs source, `-27.153%` vs retained PGO) | rolled back; not stable or positive |
| Refreshed PGO retrain on current retained head with pinned training runs in `build-pgo-pin` | source head `23.116 / 65.424 / 106.310 ms`, retained PGO `22.111 / 61.608 / 95.670 ms` | clean pinned retry: `24.590 / 74.514 / 109.405 ms` (`-7.010%` vs source, `-16.233%` vs retained PGO) | rolled back |

### Re-evaluated against retained head `23.116 / 65.424 / 106.310 ms`

These retries were run after retaining the direct-stack `string.find()` rewrite.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Direct stack/top access in `get_slice_params()` with direct string/array length reads | `23.116 / 65.424 / 106.310 ms` | clean retry 1: `23.246 / 64.025 / 105.651 ms` (`+0.989%` by total), clean retry 2: `23.301 / 65.084 / 108.135 ms` (`-0.857%` by total) | rolled back; not stable enough to promote |
| Early validated `string.slice` intrinsic in `CallNative()` before the generic typecheck loop | `23.116 / 65.424 / 106.310 ms` | clean retry: `23.577 / 65.281 / 108.787 ms` (`-1.434%` by total) | rolled back |
| Extend cached integer `tostring` range to `-32..512` | `23.116 / 65.424 / 106.310 ms` | clean retry: `23.631 / 67.893 / 103.992 ms` (`-0.342%` by total) | rolled back |
| `string.find` intrinsic fast path on top of the retained direct-stack `string.find()` rewrite | `23.116 / 65.424 / 106.310 ms` | clean retry: `23.348 / 65.350 / 112.084 ms` (`-3.044%` by total) | rolled back |
| Early zero-extra-arg intrinsic fast path in `CallNative()` for `len` / `tointeger` / `tofloat` / `tostring` | `23.116 / 65.424 / 106.310 ms` | clean retry: `23.575 / 64.985 / 106.705 ms` (`-0.213%` by total) | rolled back |
| Direct comparator dispatch in `_sort_compare()` for closure / native-closure callbacks | `23.116 / 65.424 / 106.310 ms` | clean retry: `24.952 / 77.974 / 113.565 ms` (`-11.106%` by total) | rolled back |
| Full-hash guard before `memcmp()` in `SQStringTable::Concat()` / `Add()` | `23.116 / 65.424 / 106.310 ms` | clean retry: `29.366 / 75.332 / 132.359 ms` (`-21.661%` by total) | rolled back |

### Re-evaluated against retained head `23.058 / 64.900 / 103.424 ms`

These retries were run after promoting the retained direct-hit `_OP_GETK` / `_OP_PREPCALLK` bypass.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Narrow fixed-arity `StartCall()` common-case fast path | `23.058 / 64.900 / 103.424 ms` | clean retry: `34.838 / 75.876 / 111.166 ms` (`-15.936%` by total) | rolled back |
| Direct-hit `_OP_GET` / `_OP_PREPCALL` bypass for `table` / `class` / `instance` member hits | `23.058 / 64.900 / 103.424 ms` | clean retry: `23.030 / 67.492 / 110.336 ms` (`-4.951%` by total) | rolled back |
| Reuse precomputed hash in the retained direct-hit `_OP_GETK` / `_OP_PREPCALLK` bypass | `23.058 / 64.900 / 103.424 ms` | clean retry: `23.299 / 66.394 / 104.323 ms` (`-1.376%` by total) | rolled back |
| `array.append` / `push` intrinsic fast path | `23.058 / 64.900 / 103.424 ms` | clean retry: `22.983 / 66.356 / 105.656 ms` (`-1.888%` by total) | rolled back |
| Cached array `append` / `push` default-delegate lookup in `_OP_PREPCALLK` | `23.058 / 64.900 / 103.424 ms` | clean retry: `23.797 / 65.398 / 106.449 ms` (`-2.227%` by total) | rolled back |

### Re-evaluated against retained head `23.708 / 65.444 / 107.847 ms`

These retries were run after this ledger was introduced, using that retained-head baseline directly instead of rerunning older baselines.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Direct non-weakref branch in `SQTable::Get()` | `23.708 / 65.444 / 107.847 ms` | clean retry: `25.209 / 68.858 / 106.261 ms` (`-1.690%` by total) | rolled back |
| Inline `SQTable::Get()` / `SQTable::Set()` into the header | `23.708 / 65.444 / 107.847 ms` | clean retry: `25.314 / 68.120 / 114.741 ms` (`-5.667%` by total) | rolled back |
| Skip `FallBackGet()` for receiver types that cannot use it | `23.708 / 65.444 / 107.847 ms` | noisy host-contended run discarded: `33.677 / 109.087 / 150.615 ms`; clean retry after core-0 contention cleared: `23.565 / 66.882 / 111.238 ms` (`-2.378%` by total) | rolled back |
| Extend cached integer `tostring` range to `-32..2048` | `23.708 / 65.444 / 107.847 ms` | clean retry: `24.066 / 68.819 / 104.777 ms` (`-0.336%` by total) | rolled back; smaller cache range worth testing separately |
| Extend cached integer `tostring` range to `-32..512` | `23.708 / 65.444 / 107.847 ms` | clean retry: `23.993 / 67.071 / 106.492 ms` (`-0.283%` by total) | rolled back |
| Rewrite `IsFalse()` as a direct type switch | `23.708 / 65.444 / 107.847 ms` | clean retry: `23.750 / 68.887 / 107.956 ms` (`-1.824%` by total) | rolled back |
| Direct primitive fast paths in `CMP_OP()` | `23.708 / 65.444 / 107.847 ms` | clean retry: `24.043 / 66.168 / 110.177 ms` (`-1.720%` by total) | rolled back |
| Skip `TryFastCallNative()` when `_intrinsic == SQ_NCI_NONE` | `23.708 / 65.444 / 107.847 ms` | clean retry: `23.645 / 67.251 / 108.410 ms` (`-1.171%` by total) | rolled back |
| Cached delegate lookup for `string.slice` / `string.find` in `_OP_PREPCALLK` | `23.708 / 65.444 / 107.847 ms` | clean retry: `24.564 / 69.023 / 108.498 ms` (`-2.582%` by total) | rolled back |
| Direct internal stack restore in `_sort_compare()` | `23.708 / 65.444 / 107.847 ms` | stacked measurement on top of the rolled-back `_intrinsic == SQ_NCI_NONE` fast-skip candidate: `25.424 / 70.906 / 110.819 ms` | discarded as non-authoritative; not a clean retained-head comparison |
| Direct stack/top access in `get_slice_params()` with direct string/array length reads | `23.708 / 65.444 / 107.847 ms` | stacked measurement on top of the rolled-back `_intrinsic == SQ_NCI_NONE` fast-skip candidate discarded; clean retry 1: `24.282 / 67.930 / 104.928 ms` (`-0.071%` by total), clean retry 2: `23.881 / 68.864 / 109.717 ms` (`-2.773%` by total) | rolled back; not stable enough to promote |
| Empty-main-bucket fast path in `SQTable::NewSlot()` | `23.708 / 65.444 / 107.847 ms` | clean retry: `24.748 / 67.146 / 115.923 ms`, checksum mismatch on `inventory_flow` (`143490352` vs `812233`) | rolled back; invalid semantics |

### Re-evaluated against retained head `24.081 / 65.150 / 105.887 ms`

These retries were run after promoting the retained `string.slice` intrinsic fast path.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| `string.find` intrinsic fast path | `24.081 / 65.150 / 105.887 ms` | clean retry: `24.355 / 64.801 / 108.427 ms` (`-1.263%` by total) | rolled back |
| Direct internal stack restore in `_sort_compare()` | `24.081 / 65.150 / 105.887 ms` | clean retry: `24.757 / 69.590 / 113.556 ms` (`-6.552%` by total) | rolled back; prior stacked measurement is superseded by this clean result |
| Early validated `string.slice` intrinsic in `CallNative()` before generic typecheck loop | `24.081 / 65.150 / 105.887 ms` | noisy first full run discarded after `inventory_flow` outlier: `23.634 / 65.834 / 150.229 ms`; clean retry: `24.273 / 66.314 / 106.046 ms` (`-0.776%` by total); `inventory_flow` sanity rerun: `106.215 ms` | rolled back |
| Pointer-walk stack-slot reset in `LeaveFrame()` | `24.081 / 65.150 / 105.887 ms` | clean retry: `24.555 / 66.008 / 109.375 ms` (`-2.470%` by total) | rolled back |
| Skip `_firstfree` rescan in `SQTable::NewSlot()` when the insertion did not consume `_firstfree` | `24.081 / 65.150 / 105.887 ms` | clean retry: `25.598 / 70.409 / 110.058 ms` (`-5.610%` by total) | rolled back |

- Cached delegate lookup directly in `SQVM::Get(...)`.
- `StringCat(...)` fast path that avoided temporary interned numerics / bool / null strings.
- Intrinsic `array.append` / `array.push`.
- Skipping `FallBackGet(...)` for types that cannot use it.
- Moving intrinsic validation ahead of generic native param/type checks in `CallNative(...)`.
- LTO / interprocedural build.
- `-march=native -mtune=native` build.
- `-fno-semantic-interposition` build.
- String-table hash guard in `SQStringTable::Add/Concat`.
- Table node-array reuse cache.
- Full monomorphic `_OP_GETK/_OP_PREPCALLK` inline cache with per-table versioning.
- Stack-liveness / skip stack-slot nulling on `LeaveFrame()`; measured faster once, but not retained due weakref-semantics risk.
- Specialized stack-slot reset helper for frame teardown.
- Direct `_OP_GETK` / `_OP_PREPCALLK` raw container hits.
- String-key specialized table/class/instance get/set/newslot paths.
- Full quicksort replacement for `array.sort`.
- Explicit cached type-name objects for `typeof` / `type()`.
- Inlining `SQTable::Get/Set`.
- Tighter `LeaveFrame()` cleanup.
- Direct non-weakref branch in `SQTable::Get`.
- Direct-stack `string.find()` rewrite.
- `string.find` intrinsic fast path.
- Direct-stack `string.slice()` rewrite.

For several of the older rolled-back candidates, the exact absolute timings were not preserved before this ledger was added. The authoritative retained / rejected status above is what survived.
