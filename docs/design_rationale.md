# Design rationale

The current prototype prioritises inspectable conversion metadata and unchanged Prolog execution over claiming unimplemented optimization.

- Conversion metadata is readable rather than an opaque encoded blob.
- The runtime delegates answer production to the original goal, preserving ordinary Prolog behavior instead of attempting unsafe partition joins.
- Scheduling, prediction, perturbation, and reassembly declarations remain metadata until their runtime semantics and equivalence tests are implemented.
- Conversion caching is session-local and keyed by source hash and selected conversion options.

The design target includes safe parallel scheduling, verified speculation, and cross-partition reassembly. Those are future implementation stages, not current guarantees; see [feature status](feature_status.md).
