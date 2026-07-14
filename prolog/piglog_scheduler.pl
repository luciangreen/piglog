:- module(piglog_scheduler, [run_generated/2]).

:- use_module(piglog_trace).
:- use_module(piglog_workers).
:- use_module(piglog_purity).
:- use_module(piglog_cost).
:- use_module(piglog_prediction).

run_generated(Generated, Options) :-
    resolve_workers(Options, Workers),
    trace_event(Options, mode_selected, execution(Options.execution), [], Events1),
    trace_event(Options, workers, Workers, Events1, Events2),
    maybe_trace_adaptive_fallback(Generated, Options, Events2, Events3),
    run_by_answer_policy(Generated.goal, Options),
    trace_event(Options, completed, success, Events3, Events4),
    emit_trace(Options, Events4).

run_by_answer_policy(Goal, Options) :-
    ( Options.answers == first ->
        once(call(Goal))
    ; call(Goal)
    ).

maybe_trace_adaptive_fallback(Generated, Options, EventsIn, EventsOut) :-
    ( Options.execution == adaptive ->
        estimate_overhead(Generated.partitions, Overhead),
        estimate_work(Generated.partitions, Work),
        ( Work =< Overhead ->
            trace_event(
                Options,
                fallback,
                adaptive_to_sequential(work(Work), overhead(Overhead)),
                EventsIn,
                EventsOut
            )
        ; trace_event(Options, adaptive_parallel_enabled, gain(work(Work), overhead(Overhead)), EventsIn, EventsOut)
        )
    ; EventsOut = EventsIn
    ).

estimate_overhead(Partitions, Overhead) :-
    length(Partitions, Count),
    Overhead is Count * 2.5.

estimate_work(Partitions, Work) :-
    findall(Cost, (member(P, Partitions), partition_cost(P, C0), cost_as_number(C0, Cost)), Costs),
    sum_list(Costs, Work).

cost_as_number(low, 1.0) :- !.
cost_as_number(medium, 3.0) :- !.
cost_as_number(high, 9.0) :- !.
cost_as_number(N, N) :- number(N), !.
cost_as_number(_, 3.0).
