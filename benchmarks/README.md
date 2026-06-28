# Benchmarks

This directory adds a small native benchmark runner plus standalone Squirrel workloads derived from `../inferno-code/scripts` patterns without depending on engine bindings.

The runner is `sqbench` and exposes separate compile and run phases:

```bash
cmake -S . -B build
cmake --build build -j
./build/bin/sqbench --compile-repeat 5 --run-repeat 25 benchmarks/workloads/registry_catalog.nut 500
./build/bin/sqbench --compile-repeat 3 --run-repeat 10 benchmarks/workloads/world_map_graph.nut 24 18 12
./build/bin/sqbench --compile-repeat 3 --run-repeat 10 benchmarks/workloads/inventory_flow.nut 2200 11
./build/bin/sqbench --compile-repeat 3 --run-repeat 10 benchmarks/workloads/session_context_flow.nut 450 12
./build/bin/sqbench --compile-repeat 3 --run-repeat 10 benchmarks/workloads/scenario_tick_flow.nut 10200 24 14
./build/bin/sqbench --compile-repeat 3 --run-repeat 10 benchmarks/workloads/volume_presence_scan.nut 650 6 12 6
```

Profile-guided optimization is supported for GCC builds through `SQ_PGO_MODE`.
The same build directory must be used for both phases so the generated profile paths match on the `USE` rebuild.
The training helper pins to CPU 0 by default when `taskset` is available and can be tuned with `CPU_PIN`, `TRAIN_COMPILE_REPEAT`, and `TRAIN_RUN_REPEAT`.
Additional CMake arguments can be passed after the build directory when a retained build variant also needs PGO retraining, for example `-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON`.

```bash
./benchmarks/train-pgo.sh
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/registry_catalog.nut 500
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/world_map_graph.nut 30 18 12
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/inventory_flow.nut 2200 11
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/session_context_flow.nut 450 12
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/scenario_tick_flow.nut 10200 24 14
./build-pgo/bin/sqbench --compile-repeat 3 --run-repeat 20 benchmarks/workloads/volume_presence_scan.nut 650 6 12 6
```

Workloads:

- `workloads/registry_catalog.nut`
  Inspired by `../inferno-code/scripts/design/item_registry/core_defs.nut` and `schema_and_helpers.nut`.
  Stresses nested literal parsing, deep cloning, stat normalization, and string-heavy table indexing.
- `workloads/world_map_graph.nut`
  Inspired by `../inferno-code/scripts/shared/campaign/hex_grid.nut` and `world_map_builder/*.nut`.
  Stresses table allocation, graph construction, string id creation, and nested lookup-heavy map building.
- `workloads/inventory_flow.nut`
  Inspired by `../inferno-code/scripts/shared/campaign/inventory_state/**/*.nut`.
  Stresses repeated table mutation, token normalization, transfers, sorting, and reward-application logic.
- `workloads/session_context_flow.nut`
  Inspired by delving-mode session/context helpers in `../inferno-code/scripts/runtime/modes/delving_mode/**`.
  Stresses repeated shared-text lookup, prefix slicing, lowercasing, route/package checks, and generated-report projection.
- `workloads/scenario_tick_flow.nut`
  Inspired by `../inferno-code/scripts/runtime/modes/delving_mode.nut` and `gameplay_and_outcome/scenario_flow.nut`.
  Stresses tick-time context refresh, route-state selection, state initialization, respawn loops, and mission/runtime gating.
- `workloads/volume_presence_scan.nut`
  Inspired by `../inferno-code/scripts/runtime/modes/delving_mode/spatial_and_loot/volume_and_context.nut`.
  Stresses tagged-volume scans, repeated position coercion, player/volume nested iteration, and generated-layer fallback checks.

The benchmark scripts are intentionally generic so VM and compiler changes can be measured in `squirrel` directly before reintegrating results into `inferno-code`.

See [RESULTS.md](RESULTS.md) for the frozen retained-head baseline and the experiment ledger.
