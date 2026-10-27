# Feature status and test coverage

This document describes behavior in the current repository, rather than the intended design in `PROGRAM_REQUIREMENTS.md`. Option acceptance or metadata generation does not imply that the corresponding runtime feature is implemented.

## Current behavior

| Area | Status | Notes |
|---|---|---|
| SWI-Prolog API | Implemented | Public predicates are listed in [the API reference](api.md). |
| Option parsing | Implemented | Supported option names and validation are listed in [the user manual](user_manual.md). |
| Source loading and hashing | Partial | Files can be loaded; source hashes are used in conversion metadata and the session cache. Saved generated artifacts are not validated and reused. |
| Partition metadata | Partial | The converter splits top-level conjunctions; it does not transform or separately execute those calls. |
| Dependency metadata | Partial | Shared variables between calls produce source-order edges. Variable modes and full data dependencies are not inferred. |
| Generated code | Partial | Readable terms can be shown, returned, and saved. They describe a conversion and are not an executable partitioned program. |
| Execution and answer policy | Partial | The original goal runs in the calling thread. `first` uses `once/1`; `all` and `ordered` use ordinary Prolog enumeration, so answer order is naturally retained. |
| Tracing | Partial | The prototype emits mode, worker-count, adaptive-estimate, and completion events. Other trace levels do not yet provide their documented full detail. |
| Execution gates | Partial | A gate on the entry predicate is enforced. Nested gates, gate-aware tracing/cache behavior, and identity hiding are not implemented. |
| Purity and cost | Partial | Simple classifications and declaration/default cost estimates exist, but they do not drive a partition scheduler. Unknown and effectful calls are not independently scheduled because no partition is scheduled. |
| Worker selection | Metadata only | `workers/1` resolves a count; workers, parallel execution, and work stealing are not implemented. |
| Adaptive/fused/pipeline/failure-first scheduling | Not implemented | Options are validated; adaptive mode can report an estimate-based event but does not change execution. |
| Predictions and perturbations | Metadata only | Declarations and thresholds can be collected/looked up. Prediction execution, verification, rollback, and perturbation application are not implemented. |
| Profiling | Not implemented | The profile cache can be cleared but is not populated or persisted. |
| Cross-partition result reassembly | Initial metadata only | Conversion metadata now assigns stable IDs to goal variables, associates IDs with partitions, and exposes a structured partition-result record constructor. The runtime does not produce these records, merge environments, join alternatives, or assemble terms; it still calls the original goal. |
| Benchmarks | Scaffold only | The benchmark runs ordinary Prolog examples and reports wall time. It does not compare execution modes, collect scheduler metrics, or validate answer equivalence. |

## Running tests

Run all plunit tests from the repository root:

```bash
swipl -q -g run_tests -t halt test/test_all.pl
```

Run individual suites:

```bash
swipl -q -g run_tests -t halt test/test_piglog.pl
swipl -q -g run_tests -t halt test/test_converter.pl
swipl -q -g run_tests -t halt test/test_scheduler.pl
swipl -q -g run_tests -t halt test/test_predictions.pl
swipl -q -g run_tests -t halt test/test_gates.pl
swipl -q -g run_tests -t halt test/test_reassembly.pl
```

The existing tests cover basic API execution and code return/save, partition/dependency presence, source-hash metadata, `answers(first)` and ordered enumeration, trace-term collection, option acceptance for prediction thresholds, entry-goal gate enforcement, stable variable-ID metadata, and the partition-result record schema. They do not establish parallel scheduling, work stealing, speculative correctness, semantic equivalence of partition execution, environment merging, or term reassembly.

Run the benchmark scaffold with:

```bash
swipl -q -g run_benchmarks -t halt benchmark/run_benchmarks.pl
```

## Remaining implementation work

The principal remaining stage is cross-partition execution and reassembly. Explicit result records and stable variable-ID metadata are now available, but are not consumed by the scheduler. Remaining work includes deterministic environment integration, constraint-aware merges, nondeterministic compatible joins and branch provenance, partial/pipeline assembly, speculative rollback, and Detlog splice integration. Each stage needs semantic-equivalence tests before the scheduler can safely rely on it.

Other major gaps are worker-based parallel execution and work stealing; a semantics-preserving purity/effect system; genuinely adaptive, fused, pipeline, and failure-first scheduling; answer commitment for concurrent results; prediction verification and cancellation; gate-aware information-flow protections; persistent profiling; and comparative correctness-checked benchmarks. See the [release plan](releases.md) and `PROGRAM_REQUIREMENTS.md` for the fuller target specification.
