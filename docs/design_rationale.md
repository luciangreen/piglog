# Design rationale

Piglog v0.5 prioritises correctness and readability before aggressive parallelism.

- Conversion is explicit and inspectable rather than opaque.
- Execution remains safety-first: unknown purity and gated goals do not speculate.
- Adaptive scheduling is explainable with trace events.
- Caching uses source hashes and option keys to avoid stale generated artifacts.
- Experimental concepts (predictions and perturbations) are represented as explicit terms and do not silently alter verified answers.
