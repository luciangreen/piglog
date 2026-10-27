```prolog
?- use_module(prolog/piglog).
?- piglog(my_algorithm(X, Y),
          [execution(adaptive),
           trace(summary),
           code(show)]).
```

# Piglog

Piglog is an experimental in-SWI-Prolog converter and runtime-scheduling prototype. It accepts a goal or source file, produces readable partition and dependency metadata, and runs the original goal through SWI-Prolog.

The current scheduler does **not** execute partitions independently, create worker threads, or perform speculative execution. The execution and scheduling options are accepted by the API, but the runtime currently delegates directly to the original goal. See [feature status](docs/feature_status.md) for what works today and what remains.

## Current features

- `piglog/1`, `piglog/2`, `piglog_file/3`, and `piglog_convert/3`
- Readable generated metadata for top-level conjunctions and inferred variable dependencies
- Stable logical-variable IDs in conversion metadata and a structured partition-result record type
- Code display, return, and save options
- `answers(first)` using `once/1`; `answers(ordered)` and `answers(all)` using ordinary Prolog enumeration
- Trace-term collection and goal-level execution gates
- Conversion caching for the current SWI-Prolog session
- A plunit test suite and a small wall-time benchmark scaffold

These are prototype capabilities, not a claim that every option is backed by a dedicated scheduler. In particular, result records and variable IDs are not yet integrated or merged by the runtime, and prediction and perturbation declarations are collected as metadata but are not verified or used to affect execution.

## Try it

Load `prolog/piglog.pl` from the repository root in SWI-Prolog:

```prolog
?- use_module(prolog/piglog).
?- piglog(member(X, [a,b,c]), [answers(first)]).
```

Convert a goal and inspect its generated terms:

```prolog
?- piglog_convert((A is 2 + 1, B is A * 2), [], Generated).
?- piglog_show_code(Generated).
```

Capture trace events:

```prolog
?- piglog(member(X, [a,b,c]), [trace(terms(Events)), answers(first)]).
```

Run an execution-gate example:

```prolog
?- [examples/secure_learning].
?- piglog_unlock(answer_requested).
?- piglog(reveal_answer(q1, Answer), [answers(first)]).
```

## Tests and benchmarks

Install SWI-Prolog, then run the full suite from the repository root:

```bash
swipl -q -g run_tests -t halt test/test_all.pl
```

To run one test file, substitute its path, for example:

```bash
swipl -q -g run_tests -t halt test/test_gates.pl
```

The current test files are `test/test_piglog.pl`, `test/test_converter.pl`, `test/test_scheduler.pl`, `test/test_predictions.pl`, `test/test_gates.pl`, and `test/test_reassembly.pl`. The benchmark scaffold can be run with:

```bash
swipl -q -g run_benchmarks -t halt benchmark/run_benchmarks.pl
```

The benchmark currently runs ordinary Prolog cases and reports wall time; it does not compare Piglog modes or validate answer equivalence. See [feature status](docs/feature_status.md) and [the manual](docs/user_manual.md) for option semantics, limitations, and planned work.
