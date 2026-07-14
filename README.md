# Piglog

Piglog is an in-SWI-Prolog source converter and runtime scheduler. It accepts a goal or source file, creates readable partition metadata, and executes with deterministic safety-first scheduling modes.

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
- Safety-first runtime gate checks and adaptive fallback reasoning
- plunit test suite and benchmark scaffold
- Documentation set in `docs/`

## Quick start

1. `swipl`
2. `?- [prolog/piglog].`
3. `?- piglog(member(X, [a,b,c]), [answers(first)]).`

## Running tests

```bash
swipl -q -g run_tests -t halt test/test_all.pl
```

## Running benchmarks

```bash
swipl -q -g run_benchmarks -t halt benchmark/run_benchmarks.pl
```
