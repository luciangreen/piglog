# Formal behavioural specification (v0.5 baseline)

- For accepted non-speculative goals, Piglog delegates answer production to the underlying Prolog goal and therefore preserves substitutions, multiplicity, exceptions, and side-effect order.
- `answers(first)` commits to `once/1`; `answers(ordered)` and `answers(all)` preserve logical source order via normal Prolog enumeration.
- `execution(adaptive)` may report fallback to sequential when estimated overhead exceeds estimated work.
- Closed execution gates raise `permission_error(run, piglog_gate, Gate)`.
- Generated code metadata includes source hash, Piglog version, options, timestamp, partitions, and dependencies.
