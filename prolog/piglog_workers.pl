:- module(piglog_workers, [resolve_workers/2]).

resolve_workers(Options, Workers) :-
    ( Options.workers == auto ->
        current_prolog_flag(cpu_count, CPU),
        ( integer(CPU), CPU > 1 ->
            Workers is max(1, CPU - 1)
        ; Workers = 1
        )
    ; Workers = Options.workers
    ).
