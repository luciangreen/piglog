# Formal behavioural specification (current prototype)

- The runtime calls the original Prolog goal; the generated partition graph is not used to produce answers.
- `answers(first)` wraps the goal in `once/1`. `answers(ordered)` and `answers(all)` both use ordinary Prolog enumeration, preserving its substitutions, multiplicity, exceptions, and side-effect order.
- Execution and scheduling mode options are validated and recorded. They do not currently create parallel, speculative, pipelined, fused, or failure-first execution.
- Adaptive mode may emit an estimate-based trace event; it does not switch the execution path.
- A closed gate on the entry predicate raises `permission_error(run, piglog_gate, Gate)`. Gates on nested calls are not enforced by the current runtime.
- Generated metadata includes source hash, Piglog version, options, timestamp, top-level conjunction partitions, and inferred shared-variable dependencies. The saved terms are not a standalone executable conversion.
- Prediction, perturbation, profiling, and cross-partition reassembly are not runtime behaviors in this prototype.

See [feature status](feature_status.md) for known limits and the tests that can currently be run.
