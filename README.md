# Piglog

Piglog is an in-SWI-Prolog source converter and runtime scheduler.

It accepts a goal or source file, creates readable partition metadata, and executes with deterministic safety-first scheduling modes. Piglog partitions a Prolog program into the smallest independently executable sections (typically predicates, clauses, or if–then branches, depending on data dependencies). It constructs a dependency graph and schedules each partition as soon as its required variables or constraints become available. Independent partitions execute concurrently when resources permit, while dependent partitions are queued until their inputs are satisfied. Optionally, Piglog may speculatively execute partitions whose inputs are highly probable, discarding incorrect speculative results if necessary.

Piglog leaves speculative parallelism as a configurable optimisation rather than a mandatory part of the language.

```prolog
?- use_module(prolog/piglog).
?- piglog(my_algorithm(X, Y),
          [execution(adaptive),
           trace(summary),
           code(show)]).
```

## Features (v0.5 baseline)

- Public API: `piglog/1`, `piglog/2`, `piglog_file/3`, `piglog_convert/3`, `piglog_run_generated/2`, `piglog_show_code/1`, `piglog_save_code/2`, `piglog_clear_cache/0`, `piglog_clear_profile/0`, `piglog_unlock/1`, `piglog_lock/1`
- Option categories: execution mode, scheduling strategy, answer policy, trace level, code output policy
- Readable generated code terms with metadata (`piglog_generated`, source hash, version, options, generation timestamp)
- Partition extraction and value-dependency graph extraction
- Cross-partition reassembly foundations (logical-variable identifiers, environment merge/join, template assembly, rollback invalidation, explanations)
- Safety-first runtime gate checks and adaptive fallback reasoning
- plunit test suite and benchmark scaffold
- Documentation set in `docs/`

## Quick start

1. `swipl`
2. `?- [prolog/piglog].`
3. `?- piglog(member(X, [a,b,c]), [answers(first)]).`

## Showcase

Try these commands in `swipl` after loading `prolog/piglog` to see the main parts of the repository in action:

### Run a goal with adaptive scheduling

```prolog
?- piglog(member(X, [a,b,c]), [execution(adaptive), answers(ordered)]).
```

### Generate and print readable Piglog code

```prolog
?- piglog((A is 2 + 1, B is A * 2), [code(show), trace(summary)]).
```

### Save generated code to a file

```prolog
?- piglog((A is 2 + 1, B is A * 2), [code(save('generated_demo.piglog.pl'))]).
```

### Capture scheduler trace terms for inspection

```prolog
?- piglog(member(X, [a,b,c]), [trace(terms(Events)), answers(first)]).
```

### Exercise execution gates

```prolog
?- [examples/secure_learning].
?- piglog_unlock(answer_requested).
?- piglog(reveal_answer(q1, Answer), [answers(first)]).
```

## Running tests

```bash
swipl -q -g run_tests -t halt test/test_all.pl
```

## Running benchmarks

```bash
swipl -q -g run_benchmarks -t halt benchmark/run_benchmarks.pl
```
