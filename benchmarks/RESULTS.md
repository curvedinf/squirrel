# Benchmark Results Ledger

This file is the source of truth for benchmark baselines and experiment outcomes.

Policy:

- Keep the current retained-head baseline at the top of this file.
- Compare every new candidate against that retained-head baseline once.
- When a candidate is kept, promote its measured result to the new retained-head baseline here.
- Do not rerun older baselines unless we intentionally refresh the baseline set.

## Current Retained-Head Baseline

Use this for the next candidate unless a newer retained result is promoted.

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`
CPU pinning: `taskset -c 0`
Command set:

```bash
taskset -c 0 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/registry_catalog.nut 180
taskset -c 0 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/world_map_graph.nut 30 18 12
taskset -c 0 ./build-pgo-lto/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/inventory_flow.nut 3200 11
```

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.586` | `727105` |
| `world_map_graph` | `52.975` | `325170` |
| `inventory_flow` | `81.885` | `812233` |

This baseline came from retaining reusable comparator call-frame slots in `array.sort()` on top of a refreshed same-build measurement of the prior retained PGO+LTO head of `18.720 / 55.296 / 82.709 ms`, which was a `+2.092%` overall improvement.

## Historical Reference Baselines

### Immediate Prior Refreshed Retained-Head Baseline

Date: `2026-06-27`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `18.720` | `727105` |
| `world_map_graph` | `55.296` | `325170` |
| `inventory_flow` | `82.709` | `812233` |

This was a fresh pinned rerun of the previously retained PGO+LTO head, taken to compare the next source-level candidate in the current machine state before promotion.

### Immediate Prior Retained-Head Baseline

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
