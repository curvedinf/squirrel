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
Build: `./build-pgo-lto-fastdefaultget/bin/sqbench`
CPU pinning: `taskset -c 2`
Command set:

```bash
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/registry_catalog.nut 500
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/world_map_graph.nut 30 18 12
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/inventory_flow.nut 2200 11
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/session_context_flow.nut 450 12
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/scenario_tick_flow.nut 10200 24 14
taskset -c 2 ./build-pgo-lto-fastdefaultget/bin/sqbench --compile-repeat 3 --run-repeat 40 benchmarks/workloads/volume_presence_scan.nut 650 6 12 6
```

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `45.002` | `2019808` |
| `world_map_graph` | `47.863` | `325170` |
| `inventory_flow` | `45.497` | `580946` |
| `session_context_flow` | `40.739` | `593415` |
| `scenario_tick_flow` | `46.833` | `2030324` |
| `volume_presence_scan` | `47.990` | `308206` |

This retained head keeps the one-entry shared-state `string.slice` result cache, the `_OP_PREPCALLK` one-argument default-delegate natclosure fast path, the short-circuit `||` / `&&` move-retargeting reduction, the unchanged-ASCII `tolower()` / `toupper()` fast path, and now hoists the cached default-delegate method lookup (`len`, `tointeger`, `tofloat`, `tostring`) into `SQVM::Get()` so generic member lookup can satisfy those hot built-in helpers before paying the slower `InvokeDefaultDelegate()` path. After a clean custom default-delegate probe plus identical `samples/class.nut` and `samples/generators.nut` output on both the source and PGO interpreters, six-workload source checksum smoke in both orders (`344.746 ms` versus `364.595 ms`, then `351.061 ms` versus `351.929 ms`, plus tie-break `346.311 ms` versus `366.828 ms`), fresh PGO+LTO retraining, and two clean pinned long-suite pairs against the previous retained build (`273.924 ms` versus `278.036 ms`, then `273.625 ms` versus `278.657 ms`), the authoritative six-workload retained baseline is `273.924 ms` total. This promoted retained head is `4.305 ms` (`+1.547%`) faster than the previous authoritative retained baseline of `278.229 ms`. Earlier baseline sections below are preserved for history.

### Rejected on earlier prior retained head `281.347 ms`

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Route hot `string.find()` and `array.append()` / `array.push()` default-delegate natives through new `TryFastCallNative()` intrinsics so successful cached `_OP_PREPCALLK` calls can bypass generic native-frame setup | targeted direct probes kept `string.find()`, `array.append()`, and `array.push()` output identical; `samples/class.nut` and `samples/generators.nut` also still matched; six-workload source smoke won in both orders at candidate `57.669 / 59.909 / 59.468 / 55.760 / 59.215 / 63.264 ms` (`355.285 ms`) versus control `58.177 / 60.447 / 58.736 / 60.443 / 59.089 / 62.437 ms` (`359.329 ms`, `+1.125%`), then candidate `57.047 / 60.364 / 59.100 / 56.983 / 59.358 / 63.427 ms` (`356.279 ms`) versus reverse control `58.483 / 59.906 / 65.230 / 58.300 / 59.302 / 63.145 ms` (`364.366 ms`, `+2.219%`) | fresh pinned PGO+LTO lost overall: first long-suite pair regressed to candidate `44.756 / 47.621 / 44.885 / 44.971 / 50.928 / 48.590 ms` (`281.751 ms`) versus live control `45.017 / 47.322 / 45.289 / 43.583 / 49.440 / 48.127 ms` (`278.778 ms`, `-1.067%`), and reverse-order confirmation only narrowed the loss at candidate `44.554 / 47.571 / 46.031 / 44.830 / 49.182 / 48.376 ms` (`280.544 ms`) versus reverse control `45.435 / 47.773 / 45.337 / 44.787 / 48.476 / 48.574 ms` (`280.382 ms`, `-0.058%`) | rolled back; source-only win did not survive PGO |
| Skip the redundant second direct table/class/instance probe only at `_OP_GETK` / `_OP_PREPCALLK` miss sites by jumping straight into fallback/default-delegate handling, without changing the generic `Get()` direct-hit path | targeted probe kept table delegate `len()`, missing-property errors, dynamic-key misses, and class-field access behavior equivalent; `samples/class.nut` and `samples/generators.nut` also still matched | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `59.065 / 59.412 / 59.256 / 55.272 / 58.810 / 61.992 ms` (`353.807 ms` total) to candidate `62.148 / 62.204 / 61.744 / 59.865 / 64.530 / 65.135 ms` (`375.626 ms`, `-6.167%`), and reverse-order confirmation also lost at candidate `62.809 / 63.733 / 62.830 / 58.618 / 62.902 / 64.660 ms` (`375.552 ms`) versus reverse control `58.417 / 59.959 / 59.008 / 56.499 / 59.542 / 62.998 ms` (`356.423 ms`, `-5.367%`) | rolled back |
| Cache the four hot default-delegate method names (`len`, `tointeger`, `tofloat`, `tostring`) directly on each interned `SQString`, replacing repeated key classification in `_OP_PREPCALLK` and `InvokeDefaultDelegate()` | targeted fast-delegate probe stayed output-identical; `samples/class.nut` and `samples/generators.nut` also still matched; fresh retained-build callgrind on `session_context_flow` showed `FastDelegateKeyForCall()` and nearby `_OP_PREPCALLK` helper work still hot inside `SQVM::Execute()` | strong six-workload source-only win did not survive PGO: source control-first improved from control `58.747 / 65.699 / 64.630 / 55.596 / 58.541 / 63.305 ms` (`366.518 ms` total) to candidate `59.183 / 58.339 / 58.121 / 53.486 / 58.278 / 59.318 ms` (`346.725 ms`, `+5.400%`), and reverse-order source confirmation also stayed ahead at candidate `57.619 / 59.192 / 56.490 / 54.240 / 57.749 / 59.699 ms` (`344.989 ms`) versus reverse control `57.741 / 60.320 / 60.976 / 56.851 / 58.935 / 73.459 ms` (`368.282 ms`, `+6.325%`), but fresh pinned PGO+LTO lost on the first long-suite pair at candidate `46.609 / 48.703 / 46.032 / 43.409 / 48.487 / 49.361 ms` (`282.601 ms`) versus control `45.085 / 47.680 / 44.974 / 43.134 / 48.150 / 47.899 ms` (`276.922 ms`, `-2.051%`), and the reverse-order confirmation only edged ahead at candidate `47.383 / 47.937 / 46.044 / 42.973 / 48.494 / 49.403 ms` (`282.234 ms`) versus reverse control `45.352 / 47.843 / 45.108 / 43.184 / 52.547 / 48.607 ms` (`282.641 ms`, `+0.144%`) while both candidate totals still stayed above the authoritative retained baseline `281.347 ms` | rolled back; source-only win did not survive PGO |
| Rewrite `DLOAD`-fed literal-key `_OP_PREPCALL` sites into `_OP_PREPCALLK`, keeping only the non-key literal as a plain `LOAD` so stacked dual-literal setup disappears before method calls | targeted method-call probe stayed output-identical; `samples/class.nut` and `samples/generators.nut` also still matched; rebuilt debug dumps raised total `_OP_PREPCALLK` count to `527`, eliminated `_OP_PREPCALL` across the six workloads, and removed the remaining `DLOAD`-fed second-slot prepcall sites | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `58.799 / 59.688 / 64.171 / 55.313 / 59.013 / 62.807 ms` (`359.791 ms` total) to candidate `60.595 / 63.023 / 60.772 / 56.311 / 61.972 / 64.673 ms` (`367.346 ms`, `-2.100%`), and reverse-order confirmation also lost at candidate `61.261 / 61.883 / 60.594 / 58.517 / 61.648 / 64.745 ms` (`368.648 ms`) versus reverse control `58.402 / 60.438 / 58.696 / 59.259 / 59.140 / 62.781 ms` (`358.716 ms`, `-2.769%`) | rolled back |
| Fuse literal-key zero-arg calls and literal-key one-moved-arg calls into dedicated compiler-emitted opcodes, collapsing `_OP_PREPCALLK + _OP_CALL` into `CALL0K` and `_OP_PREPCALLK + _OP_MOVE + _OP_CALL` into `CALL1KMV` | targeted call-shape probe stayed output-identical for user-method and delegate calls; `samples/class.nut` and `samples/generators.nut` also still matched; rebuilt debug dumps showed `CALL0K` `184` times and `CALL1KMV` `62` times across the six workloads | not stable enough to promote: first full-suite source pass improved from control `60.351 / 61.239 / 65.260 / 56.203 / 58.930 / 63.384 ms` (`365.367 ms` total) to candidate `58.079 / 63.671 / 60.518 / 57.476 / 59.253 / 62.991 ms` (`361.988 ms`, `+0.925%`), but reverse-order confirmation lost at candidate `58.299 / 63.614 / 60.963 / 57.527 / 59.155 / 62.798 ms` (`362.356 ms`) versus reverse control `59.394 / 60.273 / 58.716 / 56.429 / 59.280 / 62.624 ms` (`354.884 ms`, `-2.106%`), and a third control-first tie-break also lost at candidate `57.623 / 64.563 / 59.159 / 56.230 / 59.060 / 63.752 ms` (`360.387 ms`) versus control `57.711 / 64.466 / 58.934 / 56.071 / 59.061 / 62.397 ms` (`358.640 ms`, `-0.487%`) | rolled back |
| Fuse stack-based `EQ` / `NE` immediately followed by `JZ` into `_OP_JCMP`, avoiding temporary bool materialization for hot conditional branches | targeted equality-branch probe matched stack-based and literal-based `==` / `!=` behavior; `samples/class.nut` and `samples/generators.nut` also still matched; rebuilt debug dumps reduced adjacent `EQ -> JZ` from `131` to `49` and `NE -> JZ` from `31` to `20` while increasing `_OP_JCMP` sites from `67` to `160` across the six workloads | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `59.361 / 60.484 / 59.112 / 56.421 / 58.932 / 61.988 ms` (`356.298 ms` total) to candidate `61.545 / 62.207 / 60.903 / 59.991 / 62.272 / 64.303 ms` (`371.221 ms`, `-4.188%`), and reverse-order confirmation also lost at candidate `60.926 / 61.886 / 60.175 / 58.778 / 62.448 / 65.210 ms` (`369.423 ms`) versus reverse control `66.786 / 60.273 / 58.716 / 56.429 / 59.280 / 62.624 ms` (`364.108 ms`, `-1.460%`) | rolled back |
| Fold up to three simple argument-setup ops between `_OP_PREPCALLK` and the following `_OP_CALL`, replaying `MOVE` / `DMOVE` / `LOAD` / `DLOAD` / `LOADINT` / `LOADFLOAT` / `LOADBOOL` directly inside the existing direct-call fast paths | targeted PREPCALLK probe stayed output-identical across user-method and delegate-method calls that exercised `MOVE`, `DMOVE`, `DLOAD`, `LOADINT`, `LOADFLOAT`, and `LOADBOOL`; `samples/class.nut` and `samples/generators.nut` also still matched | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `59.294 / 59.736 / 61.770 / 55.573 / 58.895 / 62.689 ms` (`357.957 ms` total) to candidate `61.034 / 63.242 / 62.182 / 57.775 / 61.358 / 66.385 ms` (`371.976 ms`, `-3.917%`), and reverse-order confirmation also lost at candidate `61.321 / 63.565 / 61.161 / 58.435 / 60.562 / 66.387 ms` (`371.431 ms`) versus reverse control `58.118 / 60.659 / 59.054 / 55.206 / 59.313 / 62.938 ms` (`355.288 ms`, `-4.544%`) | rolled back |
| Fuse the exact `EXISTS -> JZ -> same-key GET/GETK` interpreter sequence so successful presence checks reuse the already-resolved direct value instead of probing again | targeted present/missing/null probe stayed output-identical for literal-key, dynamic-key, array-index, and string-index cases | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `58.131 / 60.348 / 58.835 / 60.214 / 64.316 / 71.394 ms` (`373.238 ms` total) to candidate `63.426 / 64.312 / 64.614 / 59.869 / 64.634 / 67.012 ms` (`383.867 ms`, `-2.848%`), and reverse-order confirmation lost more sharply at candidate `66.552 / 65.061 / 64.163 / 60.253 / 63.174 / 67.453 ms` (`386.656 ms`) versus reverse control `60.676 / 60.881 / 59.630 / 55.782 / 59.434 / 62.563 ms` (`358.966 ms`, `-7.714%`) | rolled back |
| Inline the hot direct container-lookup helpers and specialize known-string `_OP_GETK` / `_OP_PREPCALLK` literal-key probes before the generic fallback path | all six source checksums still matched in both orders | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `58.270 / 64.317 / 58.644 / 57.106 / 59.528 / 62.518 ms` (`360.383 ms` total) to candidate `65.801 / 64.319 / 63.969 / 59.599 / 63.219 / 66.078 ms` (`382.985 ms`, `-6.272%`), and reverse-order confirmation also lost at candidate `63.154 / 63.710 / 64.060 / 58.367 / 62.291 / 67.253 ms` (`378.835 ms`) versus reverse control `58.893 / 60.011 / 59.036 / 56.096 / 58.773 / 62.858 ms` (`355.667 ms`, `-6.514%`) | rolled back |
| Extend the cached `_OP_PREPCALLK` default-delegate natclosure fast path to try successful multi-arg intrinsics through `TryFastCallNative()` before falling back to generic `CallNative()` setup | direct `slice(start,end)`, `tointeger(base)`, and `tofloat()` probe stayed output-identical; all six source checksums still matched | rejected during source smoke before a pinned PGO retry: first full-suite source pass regressed from control `62.337 / 58.760 / 58.749 / 56.064 / 59.436 / 71.508 ms` (`366.854 ms` total) to candidate `62.124 / 62.336 / 61.933 / 58.389 / 63.327 / 65.729 ms` (`373.838 ms`, `-1.903%`), and reverse-order confirmation lost more sharply at candidate `62.570 / 61.561 / 61.920 / 59.600 / 62.361 / 65.487 ms` (`373.499 ms`) versus reverse control `58.547 / 59.870 / 57.414 / 56.032 / 59.275 / 62.055 ms` (`353.193 ms`, `-5.750%`) | rolled back |

### Rejected on immediate prior retained head `278.229 ms`

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Scan `string_case_map()` for the first real `tolower()` / `toupper()` change and return the original string immediately on unchanged paths, only allocating and copying once a mapped character actually differs | clean custom case probe plus `samples/class.nut` and `samples/generators.nut` stayed output-identical against the retained source interpreter | not stable enough to justify a PGO retry: first full-suite source pass regressed from control `59.408 / 61.734 / 59.684 / 53.672 / 58.765 / 63.398 ms` (`356.661 ms` total) to candidate `66.648 / 59.052 / 58.104 / 59.673 / 58.779 / 65.012 ms` (`367.268 ms`, `-2.973%`), while reverse-order confirmation flipped the other way at candidate `59.049 / 61.032 / 59.289 / 53.489 / 58.934 / 63.278 ms` (`355.071 ms`) versus reverse control `59.508 / 61.063 / 65.833 / 54.605 / 57.997 / 63.176 ms` (`362.182 ms`, `+1.964%`) | rolled back; source results were too order-sensitive to justify PGO |

### Rejected on immediate prior retained head `284.700 ms`

These retries were run against the prior six-workload retained head after the `_OP_PREPCALLK` one-argument default-delegate natclosure fast path promotion.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| No-op fast returns in generic `SQObjectPtr` assignment operators and ref/scalar assignment macros, skipping addref/release when the destination already holds the same value | all six source checksums still matched; first full-suite source pass moved from control `61.066 / 64.689 / 59.174 / 59.868 / 62.250 / 73.650 ms` (`380.697 ms` total) to candidate `67.644 / 67.547 / 65.046 / 63.309 / 68.738 / 71.466 ms` (`403.750 ms` total) | rejected during source smoke before a pinned PGO retry, with the largest losses in `registry_catalog` (`+6.578 ms`) and `scenario_tick_flow` (`+6.488 ms`) | rolled back |
| Split out a narrower `_OP_PREPCALLK` one-argument default-delegate intrinsic helper to avoid the generic `TryFastCallNative()` stack/self setup on successful fast calls | all six source checksums still matched; first full-suite source pass improved from control `60.636 / 63.924 / 66.962 / 60.029 / 62.210 / 65.665 ms` (`379.426 ms` total) to candidate `62.947 / 64.249 / 61.891 / 58.280 / 61.370 / 66.344 ms` (`375.081 ms`, `+1.145%`) | reverse-order confirmation lost overall at candidate `63.357 / 63.845 / 61.174 / 57.276 / 62.908 / 66.941 ms` (`375.501 ms`) versus reverse control `60.428 / 63.719 / 60.883 / 60.961 / 62.376 / 64.900 ms` (`373.267 ms`, `-0.599%`) | rolled back; not stable enough to promote |
| Skip the second direct string-key member probe in `Get()` after `_OP_GETK` / `_OP_PREPCALLK` already missed the same table/class/instance slot | delegate/metamethod fallback probe stayed clean; first source pair improved from control `61.508 / 64.304 / 60.777 / 64.544 / 62.256 / 65.532 ms` (`378.921 ms`) to candidate `59.404 / 63.251 / 60.819 / 57.156 / 61.196 / 66.871 ms` (`368.697 ms`, `+2.698%`), and reverse-order source confirmation also stayed ahead at candidate `59.796 / 63.325 / 60.279 / 59.287 / 61.465 / 66.030 ms` (`370.182 ms`) versus reverse control `62.754 / 69.488 / 61.375 / 59.994 / 61.960 / 65.376 ms` (`380.947 ms`, `+2.826%`) | fresh PGO+LTO gave noisy focused reruns, but both clean full-suite long pairs still lost overall: first pair `291.830 ms` versus `286.681 ms` (`-1.796%`), reverse-order confirmation `288.374 ms` versus `286.496 ms` (`-0.655%`) | rolled back; strong source-only win did not survive PGO |

### Rejected on immediate prior retained head `286.094 ms`

These retries were run against the prior six-workload retained head after the shared-state `string.slice` result cache promotion. Each candidate passed six-workload source checksum smoke before the pinned PGO+LTO retry.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Expand the shared default-delegate method cache to array/string `append`, `push`, `slice`, `find`, `tolower`, and `toupper` for both generic `InvokeDefaultDelegate()` and `_OP_PREPCALLK` | live retained control `46.369 / 49.960 / 46.335 / 45.152 / 50.316 / 50.334 ms` | clean pinned full-suite retry: candidate `50.079 / 52.886 / 48.107 / 45.824 / 50.530 / 52.561 ms` (`299.987 ms` total versus `288.466 ms`, `-3.994%`) | rolled back |
| Limit the expanded hot-method delegate cache to `_OP_PREPCALLK` only, keeping generic `InvokeDefaultDelegate()` on the original four-key matcher | live retained control `46.369 / 49.960 / 46.335 / 45.152 / 50.316 / 50.334 ms` | clean pinned full-suite retry: candidate `48.901 / 53.115 / 48.435 / 45.047 / 51.742 / 51.365 ms` (`298.605 ms` total versus `288.466 ms`, `-3.515%`) | rolled back |
| Hash-based expanded `_OP_PREPCALLK` delegate matcher for array/string `append`, `push`, `slice`, `find`, `tolower`, and `toupper`, while keeping generic `InvokeDefaultDelegate()` on the original four-key matcher | live retained control `46.225 / 49.490 / 46.212 / 44.613 / 50.246 / 50.826 ms` | clean pinned full-suite retry: candidate `49.506 / 53.348 / 48.314 / 46.791 / 52.068 / 51.933 ms` (`301.960 ms` total versus `287.612 ms`, `-4.989%`) | rolled back |
| Fast path `StartCall()` for exact-arity, non-vararg, env-free, non-debug, non-generator closures | live retained control `46.369 / 49.960 / 46.335 / 45.152 / 50.316 / 50.334 ms` | clean pinned full-suite retry: candidate `49.005 / 51.911 / 48.514 / 47.920 / 53.249 / 52.806 ms` (`303.405 ms` total versus `288.466 ms`, `-5.179%`) | rolled back |
| Eight-slot shared-state `StringCat()` result cache keyed by the pair of interned input strings | retained source `scenario_tick` `62.305 ms`, `volume_presence` `66.750 ms` | rejected during smoke before a pinned PGO retry: all six source checksums still matched, but source directional reruns regressed to `66.838 ms` on `scenario_tick` (`+7.275%`) and `66.944 ms` on `volume_presence` (`+0.291%`) | rolled back |
| Stop `LeaveFrame()` from clearing one stack slot past the active frame, so each return only nulls the callee-owned range | source sanity passed with `samples/class.nut` and `samples/generators.nut`; first source suite improved to `60.328 / 62.916 / 60.672 / 58.867 / 62.254 / 65.910 ms` (`370.947 ms` versus `397.042 ms`, `+6.572%`), and reverse-order source confirmation stayed ahead at `60.680 / 63.276 / 60.309 / 59.008 / 64.411 / 68.565 ms` (`376.249 ms` versus `396.143 ms`, `+5.022%`) | pinned PGO+LTO stayed effectively neutral and split by order: first pair `288.543 ms` versus `288.050 ms` (`-0.171%`), reverse-order confirmation `288.241 ms` versus `288.561 ms` (`+0.111%`) | rolled back; not stable enough to promote |
| Detect the first actual `tolower()` / `toupper()` change before allocating, copying, and `memcmp`ing the whole string in `string_case_map()` | valid direct case-mapping probe matched on full-range, unchanged, and sliced `tolower()` / `toupper()` behavior; first source suite improved to `60.811 / 63.775 / 61.697 / 58.054 / 61.734 / 64.598 ms` (`370.669 ms` versus `397.808 ms`, `+6.822%`), and reverse-order source confirmation stayed ahead at `61.419 / 66.005 / 60.191 / 58.090 / 61.560 / 67.991 ms` (`375.256 ms` versus `393.872 ms`, `+4.727%`) | pinned PGO+LTO retries lost in both orders: first pair `294.163 ms` versus `292.277 ms` (`-0.645%`), reverse-order confirmation `295.220 ms` versus `287.906 ms` (`-2.540%`) | rolled back; source-only win did not survive PGO |
| Return the original string immediately for full-range `string.slice()` calls before the existing shared-state slice-result cache | retained source full suite `65.207 / 67.088 / 64.819 / 61.946 / 67.180 / 70.441 ms`; valid direct slice probe matched on `slice(0)`, `slice(0, len)`, negative-full, tail, and empty cases | source candidate improved to `65.514 / 67.100 / 65.042 / 61.095 / 66.065 / 70.146 ms` (`394.962 ms` versus `396.681 ms`, `+0.433%`), but the authoritative pinned PGO+LTO retry regressed to `50.340 / 50.443 / 47.807 / 45.288 / 50.607 / 50.880 ms` (`295.365 ms` versus live control `46.144 / 49.729 / 46.031 / 44.366 / 50.113 / 50.211 ms`, `286.594 ms` total, `-3.060%`) | rolled back |
| Move `string.tolower()` / `string.toupper()` onto the native intrinsic fast-call path so repeated string-case helpers bypass full native-frame setup | retained source full suite `66.502 / 67.779 / 65.179 / 62.801 / 66.991 / 70.820 ms` | rejected during smoke before a pinned PGO retry: all six source checksums still matched, but the source candidate moved to `65.292 / 68.816 / 65.791 / 60.718 / 69.876 / 70.919 ms` (`401.412 ms` versus `400.072 ms` total); focused source reruns also lost on `registry_catalog` `65.905` vs `64.773`, `session_context_flow` `62.991` vs `62.428`, and `scenario_tick_flow` `68.172` vs `66.893` | rolled back |
| One-entry shared-state `string.tolower()` / `string.toupper()` result cache keyed by source string plus normalized start/length and map mode | live retained control `46.369 / 49.960 / 46.335 / 45.152 / 50.316 / 50.334 ms` | clean pinned full-suite retry: candidate `49.420 / 52.981 / 48.446 / 47.231 / 52.833 / 51.638 ms` (`302.549 ms` total versus `288.466 ms`, `-4.882%`) | rolled back |
| Skip libc `tolower()` / `toupper()` for ASCII characters that are already in the requested case, while preserving the existing non-ASCII path | first live retained control `46.264 / 49.621 / 46.365 / 44.543 / 50.849 / 50.269 ms`, reverse-order live retained control `46.791 / 49.568 / 46.019 / 44.146 / 50.234 / 50.834 ms` | six-workload source smoke stayed checksum-clean; a focused source rerun improved `session_context_flow` and `scenario_tick_flow`, but the first pinned full-suite retry lost at `47.828 / 50.003 / 46.659 / 43.755 / 50.499 / 50.781 ms` (`289.525 ms` versus `287.911 ms`, `-0.560%`), and the reverse-order confirmation only edged ahead at `46.652 / 50.008 / 46.501 / 43.917 / 49.645 / 50.719 ms` (`287.442 ms` versus `287.592 ms`, `+0.052%`) | rolled back; not stable enough to promote |
| Split `string_case_map()` into dedicated `string.tolower()` / `string.toupper()` loops so the mapper callback can be optimized away | direct case-mapping probe matched on full-range, unchanged, and sliced `tolower()` / `toupper()` behavior | all six source checksums still matched; first-order source suite was effectively flat at `64.585 / 67.499 / 64.688 / 61.670 / 67.797 / 70.917 ms` (`397.156 ms` versus live control `64.363 / 68.085 / 64.258 / 61.518 / 68.155 / 70.761 ms`, `397.140 ms` total), reverse-order source confirmation improved to `70.453 / 67.280 / 61.197 / 65.075 / 66.781 / 65.022 ms` (`395.808 ms` versus reverse live control `71.103 / 67.231 / 61.600 / 64.905 / 68.051 / 64.721 ms`, `397.611 ms` total, `+0.453%`), but pinned PGO+LTO lost on the cleaner reverse-order retry at `50.758 / 51.346 / 46.398 / 47.190 / 51.380 / 48.576 ms` (`295.648 ms` versus reverse live control `51.304 / 51.211 / 44.171 / 46.197 / 50.465 / 48.548 ms`, `291.896 ms`, `-1.286%`); an earlier first-order PGO pair was discarded because the live control spiked `registry_catalog` to `76.467 ms` | rolled back |
| Route `_OP_CAT3` string concatenation through direct string-table concat helpers instead of building a scratch buffer and then calling `SQString::Create()` | direct concat probe matched on three-string, empty-segment, and mixed primitive `string + value + value` cases | all six source checksums still matched; first-order source suite improved from live control `66.319 / 67.988 / 64.139 / 61.830 / 67.951 / 70.492 ms` (`398.719 ms` total) to candidate `62.092 / 63.936 / 60.422 / 59.014 / 63.012 / 65.780 ms` (`374.256 ms`, `+6.135%`), and reverse-order source confirmation stayed ahead at candidate `66.911 / 63.907 / 59.215 / 62.813 / 65.734 / 61.918 ms` (`380.498 ms`) versus reverse live control `70.575 / 67.710 / 62.182 / 64.273 / 68.878 / 63.988 ms` (`397.606 ms`, `+4.302%`); pinned PGO+LTO then lost in both orders at `47.341 / 49.750 / 47.090 / 45.919 / 49.844 / 51.375 ms` (`291.319 ms` versus clean live control `46.280 / 49.664 / 47.280 / 44.530 / 50.919 / 50.315 ms`, `288.988 ms`, `-0.807%`) and reverse-order candidate `51.579 / 50.306 / 45.698 / 46.515 / 50.054 / 47.376 ms` (`291.528 ms`) versus reverse live control `50.428 / 50.176 / 45.873 / 46.088 / 49.587 / 47.184 ms` (`289.336 ms`, `-0.757%`) | rolled back; strong source-only win did not survive PGO |
| Widen the prebuilt cached integer `tostring()` range from `[-32, 255]` to `[-32, 4096]` so repeated default `tostring()` calls can reuse more interned strings | direct `tostring()` boundary probe matched on `255`, `256`, `4096`, `4097`, `-32`, and string-concat uses of `4096` / `4097` | rejected during source smoke before a pinned PGO retry: all six source checksums still matched, but the first full-suite source pass slipped to `65.619 / 68.252 / 64.937 / 62.594 / 66.930 / 71.137 ms` (`399.469 ms` versus live control `64.853 / 68.218 / 64.157 / 62.702 / 67.164 / 71.206 ms`, `398.300 ms` total), and reverse-order confirmation lost more clearly at candidate `71.202 / 69.921 / 63.455 / 64.922 / 68.397 / 65.251 ms` (`403.148 ms`) versus reverse live control `70.132 / 67.103 / 62.652 / 65.023 / 67.991 / 64.367 ms` (`397.268 ms`) | rolled back |
| Concatenate a real string directly with primitive `int` / `float` / `bool` / `null` text in `StringCat()` instead of first calling full `ToString()` on the primitive side | direct concat probe matched on `string + int`, `int + string`, large integer, float, bool, and null cases in both orders | rejected during source smoke before a pinned PGO retry: all six source checksums still matched, but the first full-suite source pass regressed to `65.434 / 67.908 / 66.477 / 62.759 / 67.924 / 72.180 ms` (`402.682 ms` versus live control `64.561 / 67.503 / 64.088 / 62.135 / 67.847 / 71.282 ms`, `397.416 ms` total), with losses in five of six workloads including `inventory_flow` (`+2.389 ms`) and `volume_presence_scan` (`+0.898 ms`) | rolled back |
| Value-only `foreach` fast path: when source omits the index variable, stop allocating the hidden local and avoid writing it on each iteration | targeted foreach probe matched on value-only and key-value loops across arrays, strings, and tables | all six source checksums still matched; first-order source suite improved to `63.826 / 66.253 / 64.010 / 61.322 / 65.858 / 69.921 ms` (`391.190 ms` versus live control `65.370 / 67.146 / 64.757 / 62.228 / 67.230 / 69.972 ms`, `396.703 ms`, `+1.389%`), and reverse-order confirmation stayed ahead at candidate `70.917 / 65.176 / 61.343 / 63.084 / 67.276 / 63.689 ms` (`391.485 ms`) versus reverse live control `71.389 / 66.995 / 61.995 / 63.564 / 67.085 / 65.284 ms` (`396.312 ms`, `+1.218%`); the authoritative pinned PGO+LTO retry then lost cleanly across all six workloads at `48.452 / 51.205 / 48.035 / 45.319 / 51.656 / 52.283 ms` (`296.950 ms` versus clean live control `46.467 / 49.677 / 46.058 / 44.317 / 49.688 / 51.146 ms`, `287.353 ms`, `-3.339%`) | rolled back; source-only win did not survive PGO |
| Expand the shared-state `string.slice` result cache from one exact source/start/length entry to a four-entry recent ring buffer | direct plus compiled-bytecode slice probes still matched on `slice(0)`, `slice(0, len)`, negative-full, tail, empty, and repeated `"sortie.*"` prefix/suffix cases | all six source checksums still matched; first-order source suite improved to `60.869 / 65.375 / 60.338 / 64.684 / 62.473 / 64.926 ms` (`378.665 ms` versus live control `64.254 / 67.499 / 64.584 / 61.602 / 66.494 / 70.673 ms`, `395.106 ms`, `+4.161%`), and reverse-order confirmation stayed ahead at candidate `60.916 / 64.684 / 61.996 / 59.110 / 63.041 / 65.099 ms` (`374.846 ms`) versus reverse live control `64.497 / 67.674 / 65.541 / 62.471 / 67.341 / 71.110 ms` (`398.634 ms`, `+5.966%`); the authoritative pinned PGO+LTO retry then lost cleanly across all six workloads at `47.592 / 50.821 / 46.743 / 46.295 / 51.721 / 51.206 ms` (`294.378 ms` versus clean live control `46.937 / 49.434 / 45.903 / 44.723 / 49.981 / 50.217 ms`, `287.195 ms`, `-2.501%`) | rolled back; strong source-only win did not survive PGO |
| One-entry `SQTable` string-key hit cache, invalidated on structural mutation, so repeated `key in table` plus `table[key]` can reuse the last resolved node | direct table probe matched repeated string-key `in`/`get`, existing-key `set`, new-slot insertion, and repeated launch-context lookups | all six source checksums still matched; first-order source suite improved to `62.295 / 65.108 / 62.125 / 58.765 / 63.574 / 66.770 ms` (`378.637 ms` versus live control `64.701 / 67.117 / 63.612 / 61.951 / 66.960 / 70.824 ms`, `395.165 ms`, `+4.182%`), and reverse-order confirmation stayed ahead at candidate `61.422 / 65.319 / 61.723 / 59.779 / 66.044 / 66.414 ms` (`380.701 ms`) versus reverse live control `65.650 / 66.363 / 64.729 / 63.130 / 67.409 / 71.008 ms` (`398.289 ms`, `+4.416%`); the authoritative pinned PGO+LTO retry then lost cleanly across all six workloads at `47.913 / 51.747 / 47.194 / 46.610 / 50.697 / 51.628 ms` (`295.789 ms` versus clean live control `46.767 / 49.376 / 45.808 / 44.013 / 49.972 / 50.341 ms`, `286.277 ms`, `-3.322%`) | rolled back; source-only win did not survive PGO |
| String-key `ExistsStr()` specialization for `_OP_EXISTS` on tables, classes, and instances, avoiding the generic `SQObject` compare path for string-key `in` checks | direct probe matched table/class/instance `in` behavior for present and missing members | rejected during source smoke before a pinned PGO retry: all six source checksums still matched, but the first full-suite source pass slipped to `64.449 / 69.682 / 65.258 / 62.930 / 66.290 / 69.821 ms` (`398.430 ms` versus live control `65.241 / 68.150 / 64.181 / 62.281 / 66.025 / 70.696 ms`, `396.574 ms` total), and reverse-order confirmation lost more clearly at candidate `64.188 / 67.484 / 66.357 / 62.543 / 68.039 / 70.075 ms` (`398.686 ms`) versus reverse live control `64.469 / 67.847 / 63.908 / 60.545 / 66.173 / 70.434 ms` (`393.376 ms`) | rolled back |
| Early one-argument intrinsic fastcall for `tostring`, `len`, `tointeger`, and `tofloat` ahead of generic native-call parameter/typecheck handling | direct intrinsic probe matched one-arg `tostring` / `len` / `tointeger` / `tofloat` behavior plus the two-arg `string.tointeger(base)` fallback path | rejected during source smoke before a pinned PGO retry: all six source checksums still matched, but the first full-suite source pass regressed to `100.706 / 69.091 / 65.193 / 63.949 / 68.959 / 71.880 ms` (`439.778 ms` versus live control `64.867 / 67.935 / 64.323 / 62.778 / 67.459 / 70.977 ms`, `398.339 ms` total); a focused rerun reduced the `registry_catalog` spike to `66.034 ms` versus `64.759 ms`, but the reverse-order confirmation still lost broadly at candidate `65.988 / 67.064 / 64.945 / 64.219 / 68.185 / 69.913 ms` (`400.314 ms`) versus reverse live control `64.636 / 67.037 / 63.529 / 61.725 / 66.940 / 69.694 ms` (`393.561 ms`) | rolled back |
| VM-local short-lived reuse of successful direct string-key lookups across nearby `_OP_EXISTS`, `_OP_GET`, and `_OP_GETK` sequences | direct probe matched table/class/instance presence checks plus repeated `exists`-then-`get` access on launch-context-like tables | rejected during source smoke before a pinned PGO retry: all six source checksums still matched, but the first full-suite source pass regressed sharply to `67.163 / 71.530 / 70.940 / 63.184 / 72.750 / 82.683 ms` (`428.250 ms` versus live control `64.740 / 67.727 / 64.224 / 61.797 / 67.058 / 70.464 ms`, `395.010 ms` total), with the largest losses in `volume_presence_scan` (`+12.219 ms`) and `inventory_flow` (`+6.716 ms`) | rolled back |

### Rejected on immediate prior retained head `287.615 ms`

These retries were run directly against the previous six-workload retained head before the slice-cache promotion.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Early intrinsic fast path in `CallNative()` before the generic type-mask walk for `len`, `tofloat`, `tostring`, numeric-base `tointeger`, and `string.slice` | live retained control `46.327 / 49.320 / 46.497 / 44.461 / 49.899 / 51.148 ms` | clean pinned full-suite retry: candidate `49.158 / 49.742 / 46.740 / 45.011 / 52.060 / 51.540 ms` (`294.251 ms` total versus `287.652 ms`, `-2.295%`) | rolled back |
| Remove `TryFastCallNative()`'s unused `suspend` / `tailcall` out-parameters and zero them once in `CallNative()` | live retained control `47.112 / 49.313 / 46.324 / 44.417 / 49.826 / 50.664 ms` | clean pinned full-suite retry: candidate `48.213 / 53.631 / 47.429 / 44.525 / 50.505 / 50.453 ms` (`294.756 ms` total versus `287.656 ms`, `-2.468%`) | rolled back |
| Interned-string `ExistsStr()` follow-up for `_OP_EXISTS` table/class/instance paths | first live control `46.014 / 49.844 / 46.157 / 44.713 / 51.576 / 51.452 ms`, confirmation live control `46.917 / 48.923 / 46.352 / 46.005 / 49.748 / 50.598 ms` | first pinned full-suite retry lost at `46.816 / 49.646 / 45.886 / 46.045 / 50.266 / 52.373 ms` (`291.032 ms` versus `289.756 ms`, `-0.440%`); reverse-order confirmation edged ahead at `46.279 / 49.392 / 46.413 / 45.578 / 50.399 / 50.324 ms` (`288.385 ms` versus `288.543 ms`, `+0.055%`) | rolled back; not stable enough to promote |
| `_OP_EXISTSK` compiler rewrite that removed literal-string key loads before `in` checks | live retained control `46.120 / 49.403 / 46.538 / 44.522 / 50.072 / 51.025 ms` | clean pinned full-suite retry: candidate `49.245 / 58.097 / 47.416 / 46.120 / 49.820 / 49.840 ms` (`300.538 ms` total versus `287.680 ms`, `-4.471%`) | rolled back |
| `_OP_EXISTSK` peephole rewrite that preserved the original codegen shape and only changed the emitted opcode | live retained control `46.943 / 48.857 / 47.748 / 44.620 / 50.208 / 50.361 ms` | clean pinned full-suite retry: candidate `47.847 / 50.122 / 48.252 / 45.417 / 51.585 / 53.127 ms` (`296.350 ms` total versus `288.737 ms`, `-2.637%`) | rolled back |
| Versioned monomorphic cache for repeated default-delegate string lookups on hot built-in types, with invalidation on default-delegate mutation and `_OP_PREPCALLK` native fast-call reuse | live retained control `47.008 / 49.096 / 46.344 / 44.887 / 49.830 / 50.433 ms` | clean pinned full-suite retry: candidate `47.226 / 51.075 / 47.526 / 45.527 / 51.198 / 50.725 ms` (`293.277 ms` total versus `287.598 ms`, `-1.974%`) | rolled back |
| Per-table last-hit cache for `SQTable::GetStr()`, clearing on every mutation and rehash so repeated string-key lookups can bypass the bucket walk | live retained control `45.887 / 49.139 / 46.425 / 44.925 / 50.512 / 50.642 ms` | clean pinned full-suite retry: candidate `47.808 / 51.151 / 47.033 / 45.074 / 51.945 / 51.621 ms` (`294.632 ms` total versus `287.530 ms`, `-2.470%`) | rolled back |

## Historical Reference Baselines

### Immediate Prior Six-Workload Retained-Head Baseline

Date: `2026-06-28`
Build: `./build-pgo-lto-caseascii/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `45.918` | `2019808` |
| `world_map_graph` | `47.546` | `325170` |
| `inventory_flow` | `45.501` | `580946` |
| `session_context_flow` | `43.005` | `593415` |
| `scenario_tick_flow` | `47.852` | `2030324` |
| `volume_presence_scan` | `48.407` | `308206` |

This was the retained head before the cached default-delegate lookup-in-`Get()` promotion. Its authoritative six-workload total was `278.229 ms`.

### Earlier Prior Six-Workload Retained-Head Baseline

Date: `2026-06-28`
Build: `./build-pgo-lto-logicmove/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `45.312` | `2019808` |
| `world_map_graph` | `47.475` | `325170` |
| `inventory_flow` | `45.072` | `580946` |
| `session_context_flow` | `43.461` | `593415` |
| `scenario_tick_flow` | `51.875` | `2030324` |
| `volume_presence_scan` | `48.152` | `308206` |

This was the retained head before the ASCII no-change `tolower()` / `toupper()` promotion. Its authoritative six-workload total was `281.347 ms`.

### Earlier Prior Six-Workload Retained-Head Baseline

Date: `2026-06-28`
Build: `./build-pgo-lto-prepcallfast/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `46.134` | `2019808` |
| `world_map_graph` | `49.598` | `325170` |
| `inventory_flow` | `45.304` | `580946` |
| `session_context_flow` | `44.636` | `593415` |
| `scenario_tick_flow` | `48.790` | `2030324` |
| `volume_presence_scan` | `50.238` | `308206` |

This was the retained head before the short-circuit `||` / `&&` target-retargeting promotion. Its authoritative six-workload total was `284.700 ms`.

### Earlier Prior Six-Workload Retained-Head Baseline

Date: `2026-06-28`
Build: `./build-pgo-lto/bin/sqbench`

| Workload | run_avg_ms | checksum |
| --- | ---: | ---: |
| `registry_catalog` | `46.535` | `2019808` |
| `world_map_graph` | `49.361` | `325170` |
| `inventory_flow` | `46.037` | `580946` |
| `session_context_flow` | `44.737` | `593415` |
| `scenario_tick_flow` | `50.074` | `2030324` |
| `volume_presence_scan` | `50.871` | `308206` |

This was the retained head before the shared-state `string.slice` result cache was promoted. Its authoritative six-workload total was `287.615 ms`.

### Earlier Prior Six-Workload Retained-Head Baseline

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
| One-entry shared-state `string.slice` result cache keyed by source string plus normalized start/length | retained PGO+LTO head `46.535 / 49.361 / 46.037 / 44.737 / 50.074 / 50.871 ms` | six-workload source checksum smoke, direct plus compiled-bytecode slice probes, `samples/class.nut`, `samples/generators.nut`, fresh PGO+LTO retraining, clean pinned full-suite retry `47.226 / 51.075 / 47.526 / 45.527 / 51.198 / 50.725 ms` versus live control `47.008 / 49.096 / 46.344 / 44.887 / 49.830 / 50.433 ms` (`+0.102%` by total), and reverse-order confirmation promoted `46.027 / 49.385 / 46.108 / 44.464 / 49.960 / 50.150 ms` versus live control `47.060 / 49.232 / 46.195 / 44.512 / 50.063 / 50.662 ms`; later canonical `./build-pgo-lto/bin/sqbench` refreshes on the same source were discarded as host-noisy | `+0.529%` |
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

### Re-evaluated against retained six-workload head `46.535 / 49.361 / 46.037 / 44.737 / 50.074 / 50.871 ms`

These retries were run after retaining the ASCII-fast string-case/interner change.

| Change | Frozen baseline | Retry results | Outcome |
| --- | --- | --- | --- |
| Wider fast-delegate cache for `array.push` / `array.append` / `*.slice` / `string.tolower()` | `46.535 / 49.361 / 46.037 / 44.737 / 50.074 / 50.871 ms` | six-workload source smoke kept checksums clean, and direct plus compiled-bytecode delegate probes still matched for `push`, `append`, `slice`, `tolower`, `tointeger`, and `tofloat`. The live retained control measured `46.263 / 49.360 / 47.339 / 44.671 / 50.500 / 50.928 ms`, while the candidate measured `48.784 / 50.937 / 46.752 / 43.200 / 50.569 / 52.227 ms` (`-1.180%` by total) | rolled back |
| Identical-value fast paths in `SQObjectPtr` copy assignment and ref-type pointer assignment | `46.535 / 49.361 / 46.037 / 44.737 / 50.074 / 50.871 ms` | six-workload source smoke kept checksums clean, but the pinned PGO+LTO candidate landed at `50.266 / 52.191 / 48.468 / 45.555 / 52.649 / 53.834 ms`, well behind the live retained control total of `289.061 ms` (`-4.810%` by total) | rolled back |

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
