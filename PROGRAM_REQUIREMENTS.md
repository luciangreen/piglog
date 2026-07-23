Piglog Prolog Program Requirements for GitHub Copilot Agent

1. Project summary

Piglog is an in-SWI-Prolog source converter and runtime scheduler.

It accepts a loaded Prolog predicate or a Prolog source file, analyses and partitions the program, generates Piglog-compatible Prolog code, and runs the resulting algorithm inside SWI-Prolog.

The user may choose whether generated code is:

* executed only;
* displayed in the REPL;
* returned as a Prolog term;
* saved to a file;
* or displayed, saved and executed.

Piglog preserves the logical meaning of the accepted input program. Its main purpose is to improve execution by scheduling compiler-selected code segments according to their dependencies, cost, readiness, predicted values and likelihood of failure.

Piglog is initially implemented entirely in Prolog and targets SWI-Prolog only.

⸻

2. Position in the converter pipeline

Piglog is the final runtime optimisation stage in the following conceptual pipeline:

Spec to Algorithm
→ Starlog
→ Loop2
→ PLOP
→ Detlog
→ Piglog

The responsibilities of the preceding stages are:

* Spec to Algorithm: constructs or merges algorithms using decision-tree structures.
* Starlog: performs syntactic optimisation and source normalisation.
* Loop2: converts suitable collection and findall structures into deterministic loops.
* PLOP: performs semantic optimisation and removes unnecessary variable pathways.
* Detlog: converts nondeterministic control structures, cuts and choicepoints into deterministic loops, branches and splices.
* Piglog: partitions the resulting algorithm and schedules safe partitions for sequential, parallel, adaptive or speculative execution.

For the first release, Piglog must not require these repositories to be installed. It must define a simple pre-Piglog interface and accept ordinary Prolog where safe.

Piglog should recognise optional transformation declarations such as:

:- transformed_by(s2a, Version).
:- transformed_by(starlog, Version).
:- transformed_by(loop2, Version).
:- transformed_by(plop, Version).
:- transformed_by(detlog, Version).

These declarations are informative rather than trusted proofs. Piglog must still inspect the input for unsupported cuts, unsafe side effects and uncontrolled nondeterminism.

⸻

3. Primary REPL interface

The main command is:

piglog(Goal, Options).

Example:

?- piglog(calculate(Input, Output),
          [execution(adaptive),
           scheduling(failure_first),
           answers(ordered),
           trace(summary),
           code(show)]).

The source-file form is:

piglog_file(File, Goal, Options).

Example:

?- piglog_file('example.pl',
               solve(Input, Output),
               [execution(parallel),
                trace(schedule),
                code(save)]).

Piglog must also provide a simpler default form:

piglog(Goal).

This is equivalent to:

piglog(Goal,
       [execution(adaptive),
        scheduling(normal),
        answers(ordered),
        trace(false),
        code(none)]).

⸻

4. Code output options

The code/1 option controls generated-code output.

Supported values are:

code(none)
code(show)
code(return(Variable))
code(save)
code(save(File))
code(show_and_save)
code(show_save_and_run)

Examples:

?- piglog(test(X), [code(show)]).

Prints the generated program and runs it.

?- piglog(test(X), [code(return(Code))]).

Returns the generated source representation in Code.

?- piglog_file('test.pl',
               test(X),
               [code(save)]).

Saves the generated program as:

test.piglog.pl

Saved generated code must include:

:- piglog_generated.
:- piglog_source_hash(Hash).
:- piglog_version(Version).
:- piglog_options(Options).
:- piglog_generated_at(Date).

Piglog may reuse a saved generated file only when:

* the source hash matches;
* the Piglog version matches;
* relevant conversion options match;
* and the generated file passes validation.

Runtime profiling changes should affect scheduling without forcing code regeneration unless the partition graph itself changes.

⸻

5. Execution option categories

Piglog must separate execution behaviour into three intuitive option categories.

5.1 Execution mode

execution(sequential)
execution(parallel)
execution(adaptive)
execution(speculative)

Sequential

Runs one ready partition at a time.

Readiness and dependency information may change the execution order, but only one partition actively executes at once.

Sequential mode is not necessarily identical to ordinary left-to-right Prolog execution.

For debugging, Piglog must also support:

execution(prolog_order)

This mode follows the accepted source order as closely as possible and does not parallelise or speculate.

Parallel

Runs independent, pure and sufficiently expensive ready partitions concurrently.

Adaptive

Automatically chooses between sequential, fused and parallel execution according to estimated benefit.

This is the default.

Speculative

Allows pure partitions to begin with predicted, partial or provisional values.

Speculative results must be verified before they are returned as logical answers or used by side effects.

⸻

5.2 Scheduling strategy

scheduling(normal)
scheduling(fused)
scheduling(pipeline)
scheduling(failure_first)

Normal

Schedules ready partitions according to dependency order and estimated benefit.

Fused

Combines small adjacent partitions when separate scheduling would cost more than direct execution.

Pipeline

Allows a downstream partition to start when sufficient partial output has become available from an upstream partition.

Failure first

Prioritises inexpensive partitions with a high estimated probability of failure.

The default ranking formula should be conceptually similar to:

failure probability / estimated execution cost

⸻

5.3 Answer policy

answers(first)
answers(all)
answers(ordered)

First

Returns the first valid answer according to the original logical answer order, not merely the first worker to finish.

All

Returns all valid answers. Their completion order need not match source order unless explicitly requested.

Ordered

Computes answers concurrently where safe but presents them in normal logical order.

This is the default.

⸻

6. Automatic partitioning

Piglog must automatically divide an algorithm into compiler-selected executable segments called partitions.

A partition may contain:

* one predicate call;
* several adjacent predicate calls;
* a condition or guard;
* an if-then branch;
* a loop;
* a deterministic splice operation;
* or another compiler-selected region.

A partition should be created only when doing so is expected to improve:

* parallel scheduling;
* failure detection;
* pipeline execution;
* prediction;
* caching;
* or dependency tracking.

Small neighbouring operations should be fused rather than scheduled independently.

Users do not manually define ordinary partition boundaries.

Optional override declarations may be supported:

:- piglog_parallel(predicate/arity).
:- piglog_sequential(predicate/arity).
:- piglog_fuse(predicate/arity).
:- piglog_no_speculation(predicate/arity).

These declarations override scheduling but do not replace automatic partition analysis.

⸻

7. Dependency graph

Piglog must construct a value-dependency graph for every converted entry predicate.

The graph must represent dependencies on values rather than merely source-code order.

Supported dependency forms include:

requires_bound(Variable)
requires_partial(Variable)
requires_constraint(Constraint)
requires_prediction(Variable, MinimumConfidence)
requires_permission(Gate)
produces(Variable)
produces_partial(Variable)

A partition becomes runnable when its declared or inferred requirements are satisfied.

The graph may be changed dynamically when:

* an execution gate opens or closes;
* a prediction is revoked;
* a partition fails;
* a provisional value becomes verified;
* a pipeline produces a partial result;
* or runtime profiling shows that partitions should be fused.

Dynamic changes must not alter the program’s verified logical meaning.

PLOP is responsible for proving removal of unnecessary variable pathways. Piglog may simplify or suspend pathways at runtime but should not claim a formal semantic proof.

⸻

8. Readiness model

Piglog uses the following fixed readiness scale:

0 — Idle
1 — Invariants and types available
2 — Constraints available
3 — Probable values available
4 — Partial bindings available
5 — Complete required bindings available

Every partition has a minimum readiness requirement.

Example:

:- piglog_readiness(classify/2, 4).

Custom readiness conditions may also be declared:

:- piglog_ready_when(
       classify/2,
       [bound(1),
        confidence(2, 0.85)]
   ).

Another example:

:- piglog_ready_when(
       calculate_price/3,
       [constraint(number(1)),
        bound(2)]
   ).

Readiness may decrease when a speculative assumption is revoked.

Ordinary non-speculative execution should generally move monotonically toward level 5.

⸻

9. Predictions

Piglog predictions may come from:

* splice tables;
* memoised results;
* previous executions;
* programmer hints;
* runtime profiling;
* heuristic rules;
* input patterns;
* or combinations of these sources.

A prediction must carry:

* the predicted value;
* a confidence score between 0.0 and 1.0;
* its source;
* its assumptions;
* and a verification method.

Conceptual generated representation:

piglog_prediction(
    Variable,
    PredictedValue,
    Confidence,
    Source,
    Assumptions,
    VerificationGoal
).

A per-predicate threshold may be declared:

:- piglog_prediction_threshold(classify/2, 0.90).

A call-level override may be supplied:

prediction_threshold(0.85)

The predicate-specific threshold takes precedence unless the call explicitly states:

prediction_override(true)

Predictions are revocable.

A prediction may initiate pure computation, but a predicted result must not:

* be returned as a confirmed answer;
* trigger an irreversible side effect;
* be written to a permanent verified cache;
* pass through a closed execution gate;
* or be described as certain

until verification succeeds.

When a prediction is wrong, Piglog must:

1. cancel dependent speculative partitions;
2. discard their immutable environments;
3. invalidate derived provisional values;
4. rerun affected partitions using confirmed information;
5. record the prediction failure for future scheduling.

The default speculative depth is:

speculation_depth(1)

Users may increase it explicitly.

⸻

10. Perturbations

Perturbations are a formal Piglog feature.

A perturbation is a provisional logical, dependency or value approximation used to begin or reprioritise computation before complete certainty is available.

Piglog supports three types:

logical
dependency
value

The intuitive declaration form is:

:- piglog_perturbation(
       Name,
       Type,
       Approximation,
       Confidence,
       Assumptions,
       VerificationGoal,
       FallbackGoal
   ).

Example:

:- piglog_perturbation(
       likely_category,
       value,
       estimated_category(Input, Category),
       0.85,
       [known_type(Input)],
       confirm_category(Input, Category),
       classify_normally(Input, Category)
   ).

Perturbations must be visible in generated code.

Sequential, parallel and adaptive modes must ignore unverified perturbations unless the user enables:

use_perturbations(true)

Speculative mode enables them by default.

A perturbation may affect scheduling or provisional computation, but it must never silently alter verified logical results.

⸻

11. Runtime scheduler

Piglog uses hybrid scheduling.

Compile-time responsibilities

The converter performs:

* partition construction;
* dependency analysis;
* purity analysis;
* side-effect analysis;
* static cost estimation;
* readiness inference;
* fusion analysis;
* initial failure likelihood estimation;
* generation of the partition graph.

Runtime responsibilities

The runner performs:

* worker allocation;
* queue management;
* readiness updates;
* adaptive fusion;
* profiling;
* prediction;
* perturbation handling;
* cancellation;
* work stealing;
* execution-gate enforcement;
* result verification;
* ordered answer commitment.

Saved generated code retains dynamic runtime scheduling.

⸻

12. Work stealing

Work stealing is required in the first complete parallel release.

Idle workers may steal runnable partitions from other workers in the same Piglog query.

Cross-query work stealing is not required initially.

The user may specify:

workers(auto)

or:

workers(4)

The default is:

workers(auto)

Piglog should select a reasonable number based on SWI-Prolog facilities and available processors.

Work stealing must not change:

* verified answers;
* answer multiplicity;
* required answer order;
* side-effect order;
* or execution-gate behaviour.

⸻

13. Immutable environments

Each partition executes with an immutable environment containing the inputs and assumptions required for that partition.

A completed partition proposes outputs to the scheduler.

Outputs may be merged only when:

* variable assignments are compatible;
* assumptions are still valid;
* predictions have not been revoked;
* required execution gates are open;
* and no relevant partition has failed.

Ordinary logical binding conflicts cause the branch to fail.

Speculative binding conflicts cause the affected speculative work to be discarded and rerun.

Large immutable terms should use safe structural sharing where supported by SWI-Prolog rather than unnecessary copying.

⸻

14. Purity and side effects

Piglog must automatically classify predicates as:

pure
read_only
stateful
external_effect
unknown

Unknown predicates default to sequential execution.

Operations such as the following must be treated as effects unless explicitly proven otherwise:

write/1
format/2
read/1
open/3
close/1
asserta/1
assertz/1
retract/1
retractall/1
abolish/1
get_time/1
random/1
thread_send_message/2
shell/1
process_create/3

Effectful partitions:

* execute sequentially;
* do not run speculatively;
* execute only after dependent logical choices are committed;
* preserve source-required effect order;
* and cannot be stolen by another worker while partially executed.

Piglog may support explicit declarations:

:- piglog_pure(predicate/arity).
:- piglog_effect(predicate/arity, EffectType).

Incorrect purity declarations should be treated as programmer errors.

Exceptions from any required partition cancel the current Piglog query and are rethrown in the calling thread after worker cleanup.

⸻

15. Execution gates

Piglog uses execution gates to prevent premature computation or disclosure.

Execution gates are suitable for:

* password-protected information;
* secret values;
* examinations;
* quizzes;
* computer-aided learning;
* staged explanations;
* user-requested answer release.

Example:

:- piglog_execution_gate(
       reveal_answer/2,
       unlocked_by(answer_requested)
   ).

Example:

:- piglog_execution_gate(
       private_data/2,
       unlocked_by(authenticated(User))
   ).

By default, a closed gate prevents:

* execution;
* prediction;
* perturbation;
* result release;
* argument tracing;
* cache lookup;
* cache storage;
* and generated scheduling details.

The predicate name may appear in administrative traces, but arguments and values must remain hidden.

A stricter gate may also hide the predicate name:

:- piglog_execution_gate(
       secret_algorithm/2,
       unlocked_by(authenticated(User)),
       [hide_identity(true)]
   ).

Gated partitions must not influence observable worker timing before authorisation when doing so could reveal protected information.

Generated code must retain gate declarations.

⸻

16. Cost model

Piglog combines four cost sources:

1. programmer declarations;
2. retained runtime profiling;
3. static analysis;
4. conservative default heuristics.

Example declarations:

:- piglog_cost(expensive_search/2, high).
:- piglog_cost(validate/1, low).
:- piglog_failure_probability(validate/1, 0.70).

Runtime profiles may be keyed by:

* predicate;
* argument instantiation mode;
* approximate input size;
* execution mode;
* scheduling strategy;
* machine characteristics.

Profiling persistence is optional and off by default.

It may be enabled with:

profile(save)

Expensive predicates may receive dedicated execution slots when profiling indicates that doing so improves throughput.

Piglog should reserve some capacity for short or failure-prone partitions so long-running work cannot occupy every worker.

⸻

17. Adaptive fallback

Adaptive mode must disable parallelisation when predicted scheduling overhead is greater than or approximately equal to the predicted benefit.

Conceptually:

if expected_parallel_saving =< expected_scheduling_overhead
then run sequentially or fuse partitions

Piglog should remember recent decisions for similar input shapes during the current session.

When tracing is enabled, Piglog should explain the decision:

Piglog fused partitions 3 and 4:
estimated separate scheduling cost exceeded estimated work.

or:

Piglog selected sequential execution:
estimated work 35 microseconds;
estimated parallel overhead 120 microseconds.

⸻

18. Trace interface

Supported trace levels are:

trace(false)
trace(summary)
trace(schedule)
trace(values)
trace(full)
trace(terms(Variable))

Summary

Shows:

* selected execution mode;
* number of partitions;
* worker count;
* major fallbacks;
* final runtime summary.

Schedule

Also shows:

* readiness changes;
* queue placement;
* worker assignment;
* work stealing;
* fusion;
* cancellation;
* pipeline activation.

Values

Also shows non-secret variable production and merge events.

Full

Shows all permitted trace information, predictions, perturbations, verification and answer commitment.

Terms

Returns structured trace events:

piglog_event(Time, EventType, Details)

Execution gates always override tracing.

⸻

19. Semantic preservation

For accepted non-speculative input, Piglog must preserve:

* logical substitutions;
* answer multiplicity;
* failure behaviour;
* exceptions;
* required answer order;
* and observable side-effect order.

answers(first) returns the first answer in original logical order.

It does not return a later logical answer merely because that worker completed first.

Speculative mode may internally compute probable results but version 1 must return only verified logical answers.

No unlabelled probable answer may be presented as a Prolog answer.

⸻

20. Unsupported constructs

The initial converter may conservatively handle difficult constructs.

The default policy is:

* unsafe construct: conversion error;
* unknown purity: sequential fallback;
* unsupported optimisation: ordinary safe execution;
* unsupported speculative construct: disable speculation for that region.

The following should initially force sequential execution or produce a clear conversion warning unless safely analysed:

* unrestricted call/N;
* unknown meta-predicates;
* dynamic predicate modification;
* attributed variables;
* foreign predicates;
* non-backtrackable global state;
* thread primitives;
* unusual setup and cleanup constructs.

Remaining cuts should cause a conversion error with a message explaining that Detlog should remove or transform them first.

Example:

Piglog conversion error:
cut found in process/2.
Run the source through Detlog or rewrite the control structure.

⸻

21. Generated code structure

Generated Piglog code should remain readable Prolog.

It should contain:

piglog_entry/2
piglog_partition/4
piglog_dependency/3
piglog_readiness/3
piglog_schedule/3
piglog_merge/3
piglog_verify/2
piglog_gate/2

The exact internal arities may change, but generated code must clearly expose:

* original predicate mapping;
* partition boundaries;
* dependencies;
* readiness requirements;
* purity classifications;
* prediction rules;
* perturbations;
* execution gates;
* result merge logic.

Generated code must not be an opaque encoded blob.

⸻

22. Required public predicates

The initial public API should include:

piglog/1
piglog/2
piglog_file/3
piglog_convert/3
piglog_run_generated/2
piglog_show_code/1
piglog_save_code/2
piglog_clear_cache/0
piglog_clear_profile/0
piglog_unlock/1
piglog_lock/1

Suggested meanings:

piglog(Goal).

Converts and runs with defaults.

piglog(Goal, Options).

Converts and runs with options.

piglog_file(File, Goal, Options).

Loads, converts and runs a source file.

piglog_convert(Goal, Options, GeneratedCode).

Converts without necessarily executing.

piglog_run_generated(Generated, Options).

Runs previously generated Piglog code.

⸻

23. Error messages

Errors must be understandable and actionable.

Example:

Piglog cannot parallelise partition 4 because it calls write/1.
The partition will execute sequentially.

Example:

Piglog cannot run classify/2:
input 1 has readiness level 2, but level 4 is required.

Example:

Speculative result revoked:
prediction for Category failed verification.
Two dependent partitions were cancelled and rerun.

⸻

24. Benchmarks

Benchmarks are required from the beginning.

The benchmark suite must compare:

* ordinary SWI-Prolog;
* Piglog prolog_order;
* Piglog sequential;
* Piglog parallel;
* Piglog adaptive;
* Piglog fused;
* Piglog pipeline;
* Piglog failure-first;
* Piglog speculative with predictions disabled;
* Piglog speculative with predictions enabled.

Benchmarks must include:

* very small predicates where Piglog should avoid overhead;
* independent expensive predicates;
* cheap likely-to-fail guards;
* dependency chains;
* pipeline-compatible producers and consumers;
* mixed pure and effectful code;
* incorrect predictions;
* gated predicates;
* multiple-answer predicates;
* cases where parallel execution is slower.

Benchmark results must report:

* wall-clock time;
* CPU time where available;
* scheduling overhead;
* partitions created;
* partitions fused;
* worker utilisation;
* cancellations;
* prediction accuracy;
* verified answer equality.

Correctness is more important than speed.

⸻

25. Testing requirements

The test suite must use SWI-Prolog plunit.

Tests must cover:

* REPL command parsing;
* option validation;
* source conversion;
* generated-code display;
* generated-code saving;
* source-hash invalidation;
* partition construction;
* dependency detection;
* readiness levels;
* sequential scheduling;
* adaptive fallback;
* parallel scheduling;
* work stealing;
* answer ordering;
* side-effect ordering;
* exception propagation;
* immutable binding conflicts;
* prediction verification;
* prediction revocation;
* perturbations;
* execution gates;
* trace redaction;
* unsupported constructs;
* benchmark result validation.

For every supported example, tests must compare Piglog answers with ordinary accepted Prolog or Detlog answers.

⸻

26. Repository structure

Recommended repository layout:

piglog/
├── README.md
├── LICENSE
├── pack.pl
├── prolog/
│   ├── piglog.pl
│   ├── piglog_options.pl
│   ├── piglog_reader.pl
│   ├── piglog_converter.pl
│   ├── piglog_partition.pl
│   ├── piglog_dependencies.pl
│   ├── piglog_purity.pl
│   ├── piglog_cost.pl
│   ├── piglog_scheduler.pl
│   ├── piglog_workers.pl
│   ├── piglog_prediction.pl
│   ├── piglog_perturbation.pl
│   ├── piglog_gates.pl
│   ├── piglog_trace.pl
│   ├── piglog_codegen.pl
│   └── piglog_cache.pl
├── test/
│   ├── test_piglog.pl
│   ├── test_converter.pl
│   ├── test_scheduler.pl
│   ├── test_predictions.pl
│   ├── test_gates.pl
│   └── fixtures/
├── examples/
│   ├── sequential.pl
│   ├── parallel.pl
│   ├── adaptive.pl
│   ├── pipeline.pl
│   ├── failure_first.pl
│   ├── speculative.pl
│   └── secure_learning.pl
├── benchmark/
│   ├── run_benchmarks.pl
│   └── cases/
└── docs/
    ├── architecture.md
    ├── formal_specification.md
    ├── design_rationale.md
    ├── api.md
    ├── user_manual.md
    ├── tutorial.md
    └── releases.md

CI/CD configuration is not required in the initial task.

⸻

27. Documentation deliverables

GitHub Copilot Agent must create:

* implementation source code;
* README;
* architecture document;
* formal behavioural specification;
* design rationale;
* API reference;
* user manual;
* tutorial;
* examples;
* benchmark suite;
* test suite;
* release plan.

The README must begin with a simple example:

?- use_module(prolog/piglog).
?- piglog(my_algorithm(X, Y),
          [execution(adaptive),
           trace(summary),
           code(show)]).

⸻

28. Release plan

Release 0.1 — Core converter and REPL runner

Required:

* SWI-Prolog implementation;
* piglog/1;
* piglog/2;
* piglog_file/3;
* option parser;
* readable generated code;
* code display and saving;
* partition graph;
* dependency analysis;
* sequential execution;
* prolog_order;
* tracing;
* source-hash validation;
* semantic comparison tests.

Release 0.2 — Safe parallel runtime

Required:

* parallel execution;
* adaptive execution;
* worker pool;
* work stealing;
* automatic purity analysis;
* immutable environments;
* partition fusion;
* pipeline scheduling;
* automatic overhead fallback.

Release 0.3 — Advanced scheduling

Required:

* failure-first scheduling;
* first, all and ordered answer policies;
* runtime profiling;
* static and declared cost estimates;
* dedicated execution slots;
* retained session scheduling decisions.

Release 0.4 — Predictive Piglog

Experimental until proven:

* five-level readiness system;
* prediction sources;
* confidence thresholds;
* speculative execution;
* verification;
* cancellation;
* bounded speculative depth.

Release 0.5 — Perturbations and dynamic pathways

Experimental until proven:

* logical perturbations;
* dependency perturbations;
* value perturbations;
* dynamic dependency updates;
* execution gates;
* secure disclosure controls;
* educational answer controls.

The term version 1 refers to the completed releases from 0.1 through 0.5.

Experimental features must be clearly marked and may require:

experimental(true)

until their correctness and safety tests pass.

⸻

29. GitHub Copilot Agent implementation order

Copilot Agent should work in the following order:

1. Create the repository structure.
2. Implement option parsing and validation.
3. Implement source inspection and callable-goal extraction.
4. Implement readable partition representation.
5. Implement value-dependency analysis.
6. Implement generated-code output.
7. Implement prolog_order execution.
8. Implement dependency-driven sequential execution.
9. Add semantic-equivalence tests.
10. Implement purity and side-effect classification.
11. Implement adaptive fusion.
12. Implement worker-based parallel execution.
13. Implement work stealing.
14. Implement ordered result commitment.
15. Implement profiling and failure-first scheduling.
16. Implement predictions and verification.
17. Implement perturbations.
18. Implement execution gates.
19. Complete documentation and benchmarks.

Copilot Agent must run the complete test suite after every major stage.

It must not begin speculative execution until deterministic, sequential and parallel semantic-equivalence tests pass.

⸻

30. Acceptance criteria

Piglog version 1 is accepted when:

1. It runs inside the SWI-Prolog REPL.
2. It accepts a goal and intuitive option list.
3. It optionally shows or saves generated readable Prolog code.
4. Saved generated code can be safely reused.
5. It automatically partitions supported algorithms.
6. It builds a value-dependency graph.
7. Sequential mode runs one ready partition at a time.
8. Parallel mode runs only safe independent partitions concurrently.
9. Adaptive mode avoids parallelism when overhead would make execution slower.
10. Work stealing functions without changing logical results.
11. Side effects remain sequential and correctly ordered.
12. Ordered mode preserves logical answer order.
13. Predictions never produce unverified logical answers.
14. Incorrect predictions are cancelled and safely rerun.
15. Perturbations are explicit in generated code.
16. Execution gates prevent premature execution or disclosure.
17. Trace output explains scheduling decisions without leaking gated values.
18. Unsupported constructs generate clear warnings or errors.
19. Benchmarks include cases where Piglog improves performance and cases where it correctly disables itself.
20. Tests demonstrate semantic equivalence for all supported non-speculative programs.

⸻

31. Guiding implementation principle

Piglog must prefer simplicity, correctness and understandable generated code over theoretical maximum parallelism.

The scheduler should follow this rule:

Run a partition early only when Piglog has enough information to do so
safely, usefully and without changing the verified meaning of the program.

When uncertain, Piglog must:

1. avoid speculation;
2. avoid parallel side effects;
3. preserve logical answer order;
4. execute sequentially;
5. explain the fallback when tracing is enabled.

⸻

Additional Piglog Requirements: Cross-Partition Term Reassembly

42. Purpose

Piglog must support the reconstruction of logical answers from values, bindings, constraints, partial terms, streams, and alternative results produced by separate partitions.

This feature is called cross-partition term reassembly.

Term reassembly must preserve ordinary Prolog semantics. It must not merely concatenate worker outputs or combine values according to completion order.

Piglog must reconstruct results according to:

* the original goal and clause structure;
* shared logical-variable identities;
* the value-dependency graph;
* branch and answer provenance;
* unification compatibility;
* constraint compatibility;
* confirmation or speculation status;
* required logical answer order.

The central rule is:

Partition outputs may be computed separately, but they must be integrated as if the accepted Prolog computation had produced them in one logically consistent variable environment.

⸻

43. Terminology

Piglog must distinguish the following concepts.

Partition result

A partition result is the output produced by one execution of a partition.

It may include:

* variable bindings;
* generated constraints;
* partial terms;
* stream items;
* branch identity;
* answer identity;
* verification state;
* provenance information;
* failure information.

Logical environment

A logical environment records the bindings and constraints associated with one possible logical answer.

Parent environment

The environment from which a partition execution was derived.

Result integration

The process of merging a partition result into a compatible parent or sibling environment.

Term assembly

The process of reconstructing an enclosing term from the integrated environment.

Environment product

The compatible combination of alternative results produced by independent nondeterministic partitions.

Provisional environment

An isolated environment containing one or more unverified speculative values.

Confirmed environment

An environment whose required values and constraints have passed verification.

⸻

44. Partition-result representation

Every executed partition must return a structured result rather than relying solely on hidden worker-local variable bindings.

A suggested representation is:

piglog_partition_result(
    ResultId,
    PartitionId,
    ParentEnvironmentId,
    BranchId,
    AnswerId,
    Bindings,
    Constraints,
    PartialTerms,
    StreamOutputs,
    Status,
    Provenance,
    VerificationDependencies
).

The fields have the following meanings:

* ResultId: unique result identifier;
* PartitionId: partition that produced the result;
* ParentEnvironmentId: environment from which execution began;
* BranchId: source or transformed branch identity;
* AnswerId: logical answer-path identity;
* Bindings: variable-to-value bindings;
* Constraints: constraints introduced or refined;
* PartialTerms: enclosing or nested terms partially instantiated by the result;
* StreamOutputs: zero or more produced stream items;
* Status: confirmed, provisional, failed, cancelled, or rejected;
* Provenance: source partition, prediction, perturbation, cache, formula, or input source;
* VerificationDependencies: predictions or perturbations that must be verified.

An implementation may use a different internal term if it preserves equivalent information.

⸻

45. Stable logical-variable identity

Variables shared across partitions must have stable identities independent of worker-local Prolog variables.

The converter must assign logical-variable identifiers during partition generation.

Example:

report(Input, report(Profile, Risk, Value)) :-
    build_profile(Input, Profile),
    assess_risk(Profile, Risk),
    calculate_value(Input, Value).

Possible logical identifiers:

logical_variable(v_input, Input).
logical_variable(v_profile, Profile).
logical_variable(v_risk, Risk).
logical_variable(v_value, Value).

Partition bindings may then be represented as:

[v_profile-profile(alice, 35)]

rather than relying on a worker-local variable address.

Stable logical-variable identity is required for:

* result merging;
* conflict detection;
* rollback;
* tracing;
* replay;
* caching;
* answer-order preservation.

⸻

46. Environment representation

Piglog must maintain explicit logical environments.

Suggested representation:

piglog_environment(
    EnvironmentId,
    ParentEnvironmentId,
    BranchPath,
    Bindings,
    Constraints,
    TermFragments,
    VerificationState,
    Status
).

Possible statuses:

active
waiting
provisional
confirmed
failed
rejected
cancelled
superseded

Environments should be treated as immutable snapshots where practical.

A merge should create a new environment rather than destructively modifying a confirmed environment.

⸻

47. Basic binding integration

When a partition produces a binding, Piglog must integrate it with the current logical environment using Prolog-compatible unification.

Example:

P1: X = person(alice, Age)
P2: Age = 35

The merged environment must entail:

X = person(alice, 35)

Piglog must not treat the outputs as unrelated values.

Equivalent conceptual operation:

merge_bindings(
    [x-person(alice, age_var)],
    [age_var-35],
    [x-person(alice, 35), age_var-35]
).

The implementation must preserve:

* aliases between variables;
* repeated variable occurrences;
* nested terms;
* attributed variables where supported;
* rational-tree policy consistent with the selected SWI-Prolog semantics.

⸻

48. Binding-conflict detection

If two partition results bind the same logical variable incompatibly, they must not be merged into one answer environment.

Example:

P1: Age = 35
P2: Age = 40

The merge must fail for that combination.

The runtime must classify the conflict as one of:

ordinary_logical_failure
branch_incompatibility
constraint_conflict
speculation_mismatch
internal_reassembly_error

An ordinary incompatibility between nondeterministic alternatives is not an internal error.

A conflict caused by an incorrect speculative value must trigger speculative invalidation and rollback.

⸻

49. Constraint integration

Partition constraints must be merged using the appropriate constraint solver rather than treated as plain metadata.

Example:

P1: X #> 10
P2: X #< 20

The integrated environment must contain the conjunction:

X #> 10,
X #< 20

If a third result adds:

X #= 25

that environment must fail.

Piglog must support a conservative initial set of constraint systems, such as:

* CLP(FD);
* CLP(Q);
* CLP(R);
* dif constraints;
* ordinary unification constraints.

Unsupported attributed-variable systems must cause:

* sequential fallback;
* isolated execution;
* or an explicit unsupported-feature diagnostic.

⸻

50. Term templates

The converter must retain templates for terms that are assembled from partition outputs.

Example source:

make_item(Input, item(Name, Price, Category)) :-
    determine_name(Input, Name),
    determine_price(Input, Price),
    determine_category(Input, Category).

Suggested generated metadata:

piglog_term_template(
    template_item,
    item(
        logical_var(v_name),
        logical_var(v_price),
        logical_var(v_category)
    ),
    [v_name, v_price, v_category]
).

Once all required variables are available, Piglog may assemble:

item(Name, Price, Category)

The term may also remain partially instantiated where the original semantics permit that result.

⸻

51. Partial-term assembly

Piglog must support incremental term assembly.

Example:

Result = report(Header, Body, Footer)

The environment may evolve as follows:

report(_Header, _Body, _Footer)
report(title("Piglog"), _Body, _Footer)
report(title("Piglog"), analysis(Data), _Footer)
report(title("Piglog"), analysis(Data), references(Refs))

A downstream partition may begin when the subterm it requires becomes available, without waiting for unrelated fields.

Example:

format_header(Header, FormattedHeader)

may run after Header is produced even if Body and Footer remain unavailable.

Partial assembly must not incorrectly imply that the whole answer is confirmed.

⸻

52. Required versus optional term components

A term template must identify which components are required before:

* beginning downstream computation;
* constructing a provisional enclosing term;
* confirming the final answer.

Suggested representation:

piglog_term_requirement(
    TemplateId,
    Purpose,
    RequiredVariables
).

Example:

piglog_term_requirement(
    template_report,
    provisional_construction,
    [v_header]
).
piglog_term_requirement(
    template_report,
    final_confirmation,
    [v_header, v_body, v_footer]
).

This permits early partial execution without premature answer commitment.

⸻

53. Reassembly partitions

Piglog may generate explicit reassembly partitions.

Example:

piglog_partition(
    assemble_report,
    goal(assemble_term(template_report, Report)),
    inputs([v_profile, v_risk, v_value]),
    outputs([v_report]),
    purity(pure),
    minimum_readiness(5),
    scheduling_class(reassembly)
).

A reassembly partition must generally be lightweight and should normally execute:

* in the scheduler thread;
* in a parent worker;
* or fused with the final consuming partition.

It should not automatically become a separate thread unless assembly is expensive.

⸻

54. Environment products for nondeterministic partitions

Where independent partitions produce multiple alternatives, Piglog must form compatible products of their result environments.

Example:

colour(red).
colour(blue).
size(small).
size(large).
item(item(Colour, Size)) :-
    colour(Colour),
    size(Size).

Independent results:

Colour environments:
C1: Colour = red
C2: Colour = blue
Size environments:
S1: Size = small
S2: Size = large

The conjunction requires the compatible product:

item(red, small)
item(red, large)
item(blue, small)
item(blue, large)

Piglog must not return only same-position combinations such as:

item(red, small)
item(blue, large)

unless the original program imposes that correspondence.

⸻

55. Compatible join operation

Piglog must provide an internal compatible-join operation.

Conceptual interface:

piglog_join_results(
    LeftResults,
    RightResults,
    JoinSpecification,
    JoinedResults
).

The join must consider:

* shared logical variables;
* branch identity;
* clause identity;
* constraints;
* cut or committed-choice boundaries;
* Detlog splice metadata where available;
* answer policy;
* source-order metadata;
* speculation status.

Independent partitions with no shared variables may form a Cartesian product when required by conjunction semantics.

Partitions with shared variables must use unification-compatible joins.

⸻

56. Avoiding unnecessary Cartesian products

Piglog must avoid constructing full Cartesian products when:

* a shared variable permits indexed joining;
* a constraint filters alternatives;
* downstream computation can consume results incrementally;
* only the first ordered answer is required;
* Detlog splice metadata already provides grouped combinations;
* a failure-first predicate can eliminate alternatives early.

Example:

person(Id, Name).
account(Id, Balance).

Results should be joined on Id rather than forming every person-account pair.

Suggested indexing:

result_index(PartitionId, LogicalVariableId, ValueKey, ResultId).

⸻

57. Detlog splice integration

When input has been transformed by Detlog, Piglog should use explicit splice metadata rather than reconstructing hidden nondeterministic relationships from scratch.

Piglog must distinguish:

* independent partition joining;
* Detlog branch splicing;
* ordinary term construction;
* stream aggregation;
* answer collection.

Suggested metadata:

piglog_splice_input(
    SpliceId,
    SourcePartitions,
    KeyVariables,
    OutputTemplate,
    OrderingPolicy
).

Detlog determines which branch outputs form logical combinations.

Piglog determines:

* when source partitions run;
* whether their results are pipelined;
* whether combinations are produced incrementally;
* whether speculation is safe;
* when assembled answers may be committed.

⸻

58. Clause and branch provenance

Every partition result must preserve the clause and branch path from which it originated.

Suggested path:

branch_path([
    clause(entry/2, 1),
    if_branch(condition_4, then),
    alternative(choice_7, 2)
]).

Results from mutually exclusive branches must not be merged.

Example:

classify(X, Result) :-
    ( X > 0 ->
        Result = positive(X)
    ;
        Result = non_positive(X)
    ).

A positive(X) fragment must not be combined with bindings originating from the else branch.

⸻

59. Cut and committed-choice boundaries

Cross-partition reassembly must preserve cuts, once-only execution, and committed-choice semantics.

When a cut commits to a clause or alternative:

* results from excluded alternatives must be cancelled or ignored;
* environments belonging to excluded alternatives must not be assembled;
* already completed speculative results from excluded alternatives must remain uncommitted;
* answer-order metadata must reflect the commitment.

Where cut behaviour cannot be represented safely, Piglog must isolate the affected region or fall back to source-order execution.

⸻

60. Answer identity and ordering

Every candidate assembled answer must have an answer identity independent of worker completion order.

Suggested representation:

piglog_answer_key(
    AnswerId,
    ClauseOrder,
    AlternativeOrder,
    GeneratorIndices,
    BranchPath
).

For:

answers(ordered)

Piglog may compute later answers early but must not present them before earlier valid answers are resolved.

For:

answers(first)

Piglog may stop after the first valid answer in accepted logical order, not merely the first assembled result to finish.

For:

answers(completion_order)

confirmed answers may be returned in completion order only when explicitly requested.

⸻

61. Speculative term assembly

Piglog may assemble provisional terms from confirmed and speculative components.

Example:

Profile: confirmed
Risk: predicted
Value: confirmed

The runtime may construct:

report(Profile, PredictedRisk, Value)

with status:

provisional

The term must retain links to all unverified dependencies.

Suggested representation:

piglog_assembled_term(
    TermId,
    TemplateId,
    Term,
    EnvironmentId,
    provisional,
    [prediction_7]
).

It must not be returned as a confirmed logical answer.

⸻

62. Speculative-component verification

When a speculative component is verified, Piglog must update or replace the provisional environment.

If:

PredictedRisk = low

and verification confirms:

ActualRisk = low

the environment may be promoted to confirmed after all other requirements are satisfied.

If verification returns:

ActualRisk = high

Piglog must:

1. invalidate the provisional term;
2. cancel downstream partitions derived exclusively from it;
3. preserve unaffected confirmed components;
4. insert the confirmed value;
5. reassemble the term;
6. rerun only affected downstream partitions.

Reassembly should therefore support partial rollback rather than recomputing unrelated confirmed partitions.

⸻

63. Reassembly dependency tracking

Every assembled term must record which partition results contributed to it.

Example:

piglog_term_provenance(
    TermId,
    [
        component(v_profile, result_11),
        component(v_risk, result_18),
        component(v_value, result_14)
    ]
).

This information is required for:

* selective invalidation;
* explanation;
* debugging;
* caching;
* benchmark measurements;
* correctness checking.

⸻

64. Reassembly after rollback

After rollback, Piglog must invalidate only terms dependent on rejected results.

Example:

Profile result: confirmed
Value result: confirmed
Risk result: rejected prediction
Report term: provisional

The runtime should preserve Profile and Value, recompute only Risk, and reconstruct Report.

It should not rerun unrelated confirmed partitions unless their dependencies were also invalidated.

⸻

65. Stream-fragment assembly

Pipeline partitions may produce fragments of a larger list, tree, report, or stream.

Piglog must distinguish:

* logical lists whose order is semantically significant;
* unordered collections;
* keyed fragments;
* incremental tree nodes;
* open-ended streams.

Example ordered fragments:

fragment(1, first).
fragment(2, second).
fragment(3, third).

must assemble as:

[first, second, third]

even if fragment 3 finishes first.

For explicitly unordered results, Piglog may avoid unnecessary sorting.

⸻

66. Difference lists and incremental list construction

For list-producing pipelines, Piglog should support difference-list or equivalent append-efficient assembly.

Example:

Chunk1-Tail1
Chunk2-Tail2
Chunk3-[]

The runtime may link compatible chunks without repeatedly traversing completed prefixes.

Generated code must hide implementation details unless tracing or code output is requested.

The assembled result must remain equivalent to the source-level list.

⸻

67. Tree and nested-structure assembly

Piglog must support terms whose components are produced at different depths.

Example:

document(
    metadata(Title, Author),
    body(
        introduction(Intro),
        chapters(Chapters)
    )
)

Partitions may independently produce:

* Title;
* Author;
* Intro;
* individual chapter elements.

The assembler must use logical-variable identities and template paths such as:

term_path([1, 1]).
term_path([2, 1, 1]).
term_path([2, 2]).

Paths are metadata aids and must not replace unification semantics.

⸻

68. Aliasing preservation

If the original term repeats the same variable, reassembly must preserve that identity.

Example:

pair(X, X)

must not be reconstructed as:

pair(X1, X2)

with unrelated variables.

If separate partitions propose:

X1 = a
X2 = b

the assembly of pair(X, X) must fail because both positions refer to the same logical variable.

⸻

69. Cyclic and rational terms

Piglog must define its policy for cyclic or rational terms.

The initial implementation may either:

* support SWI-Prolog rational-tree semantics;
* require occurs-check-safe terms;
* or reject cyclic cross-partition reassembly.

The selected policy must be explicit and tested.

Suggested option:

term_policy(rational_trees)
term_policy(occurs_check)
term_policy(acyclic_only)

The default should match the safest semantics that the implementation can reliably preserve.

⸻

70. Copying and isolation

Worker-local terms must not accidentally share mutable or attributed state across threads.

The runtime must use appropriate isolation such as:

* copy_term/2;
* copy_term/3;
* duplicate_term/2;
* serialisable binding maps;
* thread-message copies;
* isolated constraint stores.

The implementation must document which term properties are preserved or stripped during transfer.

Attributes required for supported constraints must not be silently discarded.

⸻

71. Reassembly cache

Piglog may cache confirmed assembled terms.

A reassembly-cache key must include:

* source hash;
* term template;
* confirmed input bindings;
* relevant constraints;
* branch identity;
* answer identity;
* Piglog version.

Provisional assembled terms may be cached only in a provisional cache linked to their assumptions.

A provisional term must never be promoted merely because it was cached.

⸻

72. Garbage collection of environments

The runtime must release environments, fragments, and partition results when they can no longer contribute to a valid answer.

Candidates for collection include:

* rejected speculative environments;
* alternatives excluded by cut;
* superseded provisional terms;
* completed environments after answer commitment;
* cancelled pipeline fragments;
* cache-expired partial results.

Environment collection must not remove data required for ordered earlier answers that remain unresolved.

⸻

73. Required internal interfaces

Piglog should provide internal predicates equivalent to:

piglog_create_environment(
    ParentEnvironment,
    BranchPath,
    Environment
).
piglog_add_partition_result(
    Environment,
    PartitionResult,
    NewEnvironment
).
piglog_merge_environments(
    LeftEnvironment,
    RightEnvironment,
    MergedEnvironment
).
piglog_join_result_sets(
    LeftResults,
    RightResults,
    JoinSpec,
    JoinedResults
).
piglog_assemble_template(
    TemplateId,
    Environment,
    AssemblyStatus,
    Term
).
piglog_confirm_assembled_term(
    TermId,
    ConfirmedTerm
).
piglog_invalidate_result(
    ResultId,
    Reason
).
piglog_invalidate_dependent_terms(
    ResultId,
    InvalidatedTermIds
).

These predicates may remain private to the implementation.

⸻

74. Reassembly traces

The trace system must support events such as:

environment_created(EnvironmentId, ParentId).
partition_result_received(ResultId, PartitionId).
binding_integrated(EnvironmentId, VariableId, Value).
constraint_integrated(EnvironmentId, Constraint).
environment_merge_succeeded(LeftId, RightId, NewId).
environment_merge_failed(LeftId, RightId, Reason).
term_assembly_started(TermId, TemplateId).
term_component_available(TermId, VariableId, ResultId).
term_assembled(TermId, Status).
term_invalidated(TermId, Cause).
answer_committed(AnswerId, TermId).

Trace output must allow a user to understand how a final term was assembled.

⸻

75. Explanation requirements

Piglog must be able to explain:

* which partitions produced each component of a term;
* which variables linked the partitions;
* why two result environments were joined;
* why two environments were considered incompatible;
* why a term remained partial;
* which component prevented confirmation;
* why a provisional term was invalidated;
* why an answer was delayed for ordering;
* whether a Cartesian product, keyed join, splice, or direct unification was used.

Example query:

?- piglog_explain_term(TermId, Explanation).

⸻

76. Safety requirements

Term reassembly must not:

* merge mutually exclusive branch results;
* commit unverified values;
* lose variable aliasing;
* discard required constraints;
* use worker completion order as logical order;
* combine results from different parent environments accidentally;
* combine cache entries from incompatible source versions;
* expose provisional terms through side effects;
* silently omit failed components;
* reinterpret ordinary conjunction as zip-style pairing.

Where compatibility cannot be established, the merge must fail or execution must fall back conservatively.

⸻

77. Performance requirements

The assembler must avoid becoming a central bottleneck.

The implementation should use:

* indexed result lookup;
* incremental joins;
* keyed environment maps;
* early conflict detection;
* lazy Cartesian products;
* answer-demand limits;
* streaming assembly;
* selective invalidation;
* partition fusion for trivial constructors.

The benchmark suite must measure:

* environment-merge time;
* term-assembly time;
* result-index size;
* number of attempted joins;
* number of rejected joins;
* number of assembled provisional terms;
* number of invalidated terms;
* memory consumed by environments;
* reassembly overhead relative to useful computation.

⸻

78. Required tests

Add the following plunit test groups:

logical_variable_identity
binding_integration
binding_conflicts
constraint_integration
partial_term_assembly
nested_term_assembly
alias_preservation
nondeterministic_environment_products
keyed_result_joining
branch_provenance
cut_commitment
answer_ordering
speculative_term_assembly
selective_reassembly_after_rollback
stream_fragment_assembly
difference_list_assembly
environment_garbage_collection
reassembly_explanations

Required test cases include:

1. Two partitions bind different variables in one result term.
2. One partition binds a variable appearing inside another partition’s partial term.
3. Compatible constraints merge successfully.
4. Inconsistent constraints reject an environment.
5. Repeated variables preserve aliasing.
6. Independent alternatives form the correct Cartesian product.
7. Shared-key alternatives use compatible matching.
8. Mutually exclusive branches are never merged.
9. An incorrect speculative field invalidates only dependent terms.
10. Ordered answers remain ordered despite out-of-order completion.
11. A partial term enables a downstream consumer.
12. A confirmed side effect receives only a confirmed assembled term.
13. A cut excludes uncommitted alternative environments.
14. A Detlog splice is assembled according to splice metadata.
15. Unsupported attributed variables trigger safe fallback.

⸻

79. Development stages

Stage A: Explicit result records

Replace implicit reliance on worker-local variable bindings with structured partition-result records.

Stage B: Stable variable identifiers

Assign and preserve logical-variable identities across partitions.

Stage C: Single-answer environment integration

Merge deterministic partition outputs into one environment and assemble final terms.

Stage D: Constraint integration

Support selected SWI-Prolog constraint systems conservatively.

Stage E: Nondeterministic result joins

Implement compatible products, keyed joins, branch provenance, and answer identities.

Stage F: Partial and pipeline assembly

Support partial terms, streams, ordered fragments, and incremental downstream execution.

Stage G: Speculative assembly

Support provisional environments, term invalidation, selective rollback, and reassembly.

Stage H: Detlog integration

Use explicit splice metadata for deterministic branch-result combination.

Each stage must include semantic equivalence tests against ordinary SWI-Prolog.

⸻

80. Acceptance criteria

Cross-partition term reassembly is complete only when Piglog can demonstrate all of the following:

1. Two independently executed partitions contribute fields to one final compound term.
2. Shared variables unify across partition boundaries.
3. Incompatible bindings reject only the affected logical environment.
4. Constraints are preserved and checked during merging.
5. Repeated-variable aliasing is preserved.
6. Nondeterministic independent outputs produce the correct logical combinations.
7. Branch provenance prevents invalid cross-branch combinations.
8. Partial terms can unlock downstream partitions.
9. Speculative components create only provisional terms.
10. Incorrect speculation selectively invalidates and reassembles dependent terms.
11. Ordered answer presentation remains equivalent to the accepted Prolog program.
12. Detlog splice outputs can be integrated without recreating hidden choicepoints.
13. Trace and explanation output identifies the source of every term component.
14. Benchmarks report the cost and benefit of term reassembly.
15. The scheduler no longer claims explicit cross-partition reassembly while merely calling the original goal directly.

⸻

81. Final reassembly principle

Piglog must follow this rule:

Separate workers may produce pieces of an answer, but only a logically compatible environment may assemble and confirm the answer.
