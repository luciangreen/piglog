# Piglog architecture

Piglog is split into converter and runner phases.

1. `piglog_reader` validates inputs and computes source hashes.
2. `piglog_options` validates user options and fills defaults.
3. `piglog_partition` builds compiler-selected executable partitions.
4. `piglog_dependencies` builds value-dependency edges.
5. `piglog_purity`, `piglog_cost`, `piglog_prediction`, `piglog_perturbation`, and `piglog_gates` annotate execution metadata.
6. `piglog_codegen` renders readable generated Prolog terms.
7. `piglog_scheduler` executes goals with selected answer policy and adaptive fallback tracing.
8. `piglog_cache` stores generated conversion artifacts by hash and option key.

The main API module `piglog` composes all phases and exposes the public predicates.
