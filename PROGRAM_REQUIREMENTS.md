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
