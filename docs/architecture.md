# Piglog architecture

The prototype has a conversion path and a direct-goal runner. Its metadata describes partitions, but the scheduler does not execute those partitions.

1. `piglog_reader` validates callable goals, loads source files, and computes source hashes.
2. `piglog_options` validates user options and fills defaults.
3. `piglog_partition` splits top-level conjunctions and records variables appearing in each call.
4. `piglog_dependencies` adds source-order edges for variables shared between calls.
5. `piglog_reassembly` assigns stable IDs to goal variables, associates those IDs with partitions, and constructs explicit partition-result records. These records are not yet produced or merged by the runtime.
6. `piglog_purity`, `piglog_cost`, `piglog_prediction`, and `piglog_perturbation` gather preliminary execution metadata.
7. `piglog_gates` checks a gate declared for the entry predicate.
8. `piglog_codegen` renders readable metadata terms.
9. `piglog_scheduler` resolves the reported worker count, may add an adaptive estimate event, and invokes the original goal under the selected answer policy.
10. `piglog_cache` stores generated conversion dicts in dynamic predicates for the current process.

The main API module `piglog` composes these phases. The generated terms are inspectable; they are not yet a compiled program that independently schedules partitions. See [feature status](feature_status.md) for implementation boundaries.
