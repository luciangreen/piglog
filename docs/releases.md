# Release plan and implementation status

The version in `pack.pl` describes the prototype package metadata. It does not imply that every planned feature is complete.

## 0.1 Core converter and runner — partial

Implemented: basic API, option validation, readable conversion metadata, top-level conjunction partitioning, approximate dependency metadata, direct original-goal execution, basic trace terms, source hashing, code display/return/save, and entry-goal gates.

Remaining: robust source inspection, mode-aware dependency analysis, validation/reuse of saved generated artifacts, generated-code execution, and comprehensive semantic-equivalence tests.

## 0.2 Safe parallel runtime — not implemented

Planned: parallel/adaptive execution, worker pool, work stealing, safe purity/effect analysis, immutable environments, partition fusion, pipeline scheduling, and overhead-based execution choice. The current scheduler invokes the original goal on the calling thread.

## 0.3 Advanced scheduling — not implemented

Planned: actual failure-first scheduling, concurrent first/all/ordered answer handling, runtime profiling, declared/static cost estimates driving scheduling, dedicated slots, and retained decisions. Current answer options use ordinary Prolog enumeration, with `first` implemented using `once/1`.

## 0.4 Predictive Piglog — metadata only

Prediction declarations and threshold lookup exist. Prediction-driven execution, verification, cancellation, rollback, and bounded speculation are not implemented.

## 0.5 Perturbations and dynamic pathways — partial declarations

Perturbation declarations can be collected, and entry-goal execution gates can be enforced. Applying perturbations, dynamic dependency updates, nested-gate enforcement, and secure disclosure controls are not implemented.

## Cross-partition result reassembly — not implemented

The additional requirements define stages A-H: structured partition results; stable logical-variable IDs; deterministic environment integration; constraint-aware merges; nondeterministic joins and provenance; partial/pipeline assembly; speculative invalidation; and Detlog splice integration. The current prototype has a result-record schema and stable variable-ID metadata for the first two stages, but neither is used by the runtime. Implement the integration stages with semantic-equivalence tests before enabling them in scheduling.

See [feature status](feature_status.md) for precise current behavior and runnable tests.
