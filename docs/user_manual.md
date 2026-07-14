# User manual

## Default behaviour

`piglog(Goal)` is equivalent to:

```prolog
piglog(Goal,
       [execution(adaptive),
        scheduling(normal),
        answers(ordered),
        trace(false),
        code(none)]).
```

## Option highlights

- `execution(sequential|parallel|adaptive|speculative|prolog_order)`
- `scheduling(normal|fused|pipeline|failure_first)`
- `answers(first|all|ordered)`
- `trace(false|summary|schedule|values|full|terms(Var))`
- `code(none|show|return(Var)|save|save(File)|show_and_save|show_save_and_run)`

## Execution gates

Declare gate policies in source:

```prolog
:- piglog_execution_gate(secret_algorithm/2, unlocked_by(authenticated_user)).
```

Unlock at runtime:

```prolog
?- piglog_unlock(authenticated_user).
```
