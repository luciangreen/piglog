# User manual

## Load Piglog

From the repository root, load the API in SWI-Prolog:

```prolog
?- use_module(prolog/piglog).
```

Run a goal with defaults:

```prolog
?- piglog(member(X, [a,b,c])).
```

Defaults are `execution(adaptive)`, `scheduling(normal)`, `answers(ordered)`, `trace(false)`, and `code(none)`. At present, execution modes and scheduling strategies are accepted configuration values; they do not change the direct execution of the original goal.

## Public options

| Option | Accepted values | Current behavior |
|---|---|---|
| `execution/1` | `sequential`, `parallel`, `adaptive`, `speculative`, `prolog_order` | Validated and recorded; the goal still runs directly in the calling thread. Adaptive mode may emit an estimate-based trace event, but does not choose a different execution path. |
| `scheduling/1` | `normal`, `fused`, `pipeline`, `failure_first` | Validated and recorded; no partition scheduling strategy is currently applied. |
| `answers/1` | `first`, `all`, `ordered` | `first` calls the goal under `once/1`; `all` and `ordered` use ordinary Prolog backtracking and therefore retain source answer order. |
| `trace/1` | `false`, `summary`, `schedule`, `values`, `full`, `terms(Variable)` | Trace events are collected for any enabled level; `terms/1` unifies its variable with events. Other enabled levels print the events currently emitted by the prototype. |
| `code/1` | `none`, `show`, `return(Variable)`, `save`, `save(File)`, `show_and_save`, `show_save_and_run` | Prints, returns, or saves generated metadata terms. Saved terms are inspectable metadata, not an independently executable partitioned program. |
| `workers/1` | `auto`, positive integer | Resolves a worker count for metadata/tracing; no worker pool is started. |
| `profile/1` | Boolean or `save` | Validated and stored; profile collection and persistence are not implemented. |
| `speculation_depth/1` | Non-negative integer | Validated and stored; speculative execution is not implemented. |
| `use_perturbations/1` | Boolean | Validated and stored; perturbations are metadata only. |
| `experimental/1` | Boolean | Validated and stored; it does not enable unimplemented behavior. |
| `prediction_override/1` | Boolean | Validated and stored; prediction verification is not implemented. |
| `prediction_threshold/1` | Number from 0.0 to 1.0, or `prediction_threshold(Predicate, Number)` | Threshold lookup is available; predictions are not used to compute answers. |
| `piglog_readiness/2` | `piglog_readiness(Predicate, 0..5)` | Validated and stored; not used by the runtime scheduler. |
| `piglog_ready_when/2` | `piglog_ready_when(Predicate, Conditions)` | Validated and stored; not used by the runtime scheduler. |
| `source_file/1` | Atom path | Internal option used by `piglog_file/3` and generated-file naming. |

Unknown options and invalid values raise a Prolog domain/type error.

## Conversion and generated terms

`piglog_convert/3` builds a dict containing the original goal, options, source hash, partition metadata, dependency metadata, stable logical-variable IDs, purity classifications, prediction and perturbation declarations, version, and generated code terms. Generated terms include `piglog_logical_variable/1` and `piglog_partition_variables/2` facts. The internal `piglog_reassembly:make_partition_result/13` predicate constructs a `piglog_partition_result/12` record with a validated status (`confirmed`, `provisional`, `failed`, `cancelled`, or `rejected`).

The current partitioner splits a top-level conjunction. It treats all variables in each call as both required and produced, and dependencies are inferred from shared variables in source order. Variable IDs and result records are currently metadata/schema only; they are not used to merge partition environments or assemble answers. This is descriptive metadata, not a complete mode or value-flow analysis.

Use `piglog_show_code/1` to print the generated terms, or `piglog_save_code/2` to write them to a file. `code(return(Code))` returns the term list in `Code`. Although the emitted terms include source and version metadata, loading those terms does not provide a separately compiled scheduler. `piglog_run_generated/2` runs a generated dict by calling its original `goal`.

The conversion cache is in-memory and lasts only for the current SWI-Prolog session. `piglog_clear_cache/0` clears it. `piglog_clear_profile/0` currently clears the reserved profile cache; no profile data is collected.

## Execution gates

Declare a gate in the module containing the gated predicate:

```prolog
:- multifile piglog_execution_gate/2.
piglog_execution_gate(reveal_answer/2, unlocked_by(answer_requested)).
```

Open or close the named gate:

```prolog
?- piglog_unlock(answer_requested).
?- piglog_lock(answer_requested).
```

A closed gate on the entry goal raises `permission_error(run, piglog_gate, Gate)`. Gates are currently checked for the entry predicate only. Nested gated calls, argument/trace redaction, `hide_identity(true)`, timing protection, and gate-aware cache/prediction behavior are not implemented.

## Examples

Try a goal, generated code, and trace capture:

```prolog
?- piglog(member(X, [1,2,3]), [execution(adaptive), answers(ordered)]).
?- piglog((A is 2 + 1, B is A * 2), [code(show), trace(summary)]).
?- piglog(member(X, [1,2,3]), [trace(terms(Events)), answers(first)]).
```

For a complete implementation and test-coverage matrix, see [feature status](feature_status.md).
