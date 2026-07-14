:- module(piglog_options, [default_options/1, normalize_options/3]).

default_options(options{
    execution: adaptive,
    scheduling: normal,
    answers: ordered,
    trace: false,
    code: none,
    workers: auto,
    profile: false,
    speculation_depth: 1,
    use_perturbations: false,
    experimental: false,
    prediction_override: false
}).

normalize_options(UserOptions, Goal, Options) :-
    must_be(list, UserOptions),
    default_options(Default),
    foldl(apply_option(Goal), UserOptions, Default, Options).

apply_option(Goal, Option, In, Out) :-
    apply_option_det(Goal, Option, In, Out),
    !.
apply_option(Goal, Option, _, _) :-
    domain_error(piglog_option_for(Goal), Option).

apply_option_det(_, execution(Value), In, Out) :-
    memberchk(Value, [sequential, parallel, adaptive, speculative, prolog_order]),
    Out = In.put(execution, Value).
apply_option_det(_, scheduling(Value), In, Out) :-
    memberchk(Value, [normal, fused, pipeline, failure_first]),
    Out = In.put(scheduling, Value).
apply_option_det(_, answers(Value), In, Out) :-
    memberchk(Value, [first, all, ordered]),
    Out = In.put(answers, Value).
apply_option_det(_, trace(Value), In, Out) :-
    valid_trace(Value),
    Out = In.put(trace, Value).
apply_option_det(_, code(Value), In, Out) :-
    valid_code(Value),
    Out = In.put(code, Value).
apply_option_det(_, workers(auto), In, Out) :-
    Out = In.put(workers, auto).
apply_option_det(_, workers(Value), In, Out) :-
    integer(Value),
    Value > 0,
    Out = In.put(workers, Value).
apply_option_det(_, profile(Value), In, Out) :-
    must_be(boolean, Value),
    Out = In.put(profile, Value).
apply_option_det(_, profile(save), In, Out) :-
    Out = In.put(profile, save).
apply_option_det(_, speculation_depth(Value), In, Out) :-
    integer(Value),
    Value >= 0,
    Out = In.put(speculation_depth, Value).
apply_option_det(_, use_perturbations(Value), In, Out) :-
    must_be(boolean, Value),
    Out = In.put(use_perturbations, Value).
apply_option_det(_, experimental(Value), In, Out) :-
    must_be(boolean, Value),
    Out = In.put(experimental, Value).
apply_option_det(_, prediction_override(Value), In, Out) :-
    must_be(boolean, Value),
    Out = In.put(prediction_override, Value).
apply_option_det(_, prediction_threshold(Value), In, Out) :-
    number(Value),
    Value >= 0.0,
    Value =< 1.0,
    Out = In.put(prediction_threshold, Value).
apply_option_det(_, prediction_threshold(Pred, Value), In, Out) :-
    must_be(callable, Pred),
    number(Value),
    Value >= 0.0,
    Value =< 1.0,
    Out = In.put(prediction_threshold, pred(Pred, Value)).
apply_option_det(_, piglog_readiness(Pred, Level), In, Out) :-
    must_be(callable, Pred),
    integer(Level),
    between(0, 5, Level),
    Out = In.put(readiness, pred(Pred, Level)).
apply_option_det(_, piglog_ready_when(Pred, Conditions), In, Out) :-
    must_be(callable, Pred),
    must_be(list, Conditions),
    Out = In.put(ready_when, pred(Pred, Conditions)).
apply_option_det(_, source_file(File), In, Out) :-
    must_be(atom, File),
    Out = In.put(source_file, File).

valid_trace(false).
valid_trace(summary).
valid_trace(schedule).
valid_trace(values).
valid_trace(full).
valid_trace(terms(Var)) :- var(Var).

valid_code(none).
valid_code(show).
valid_code(return(Var)) :- var(Var).
valid_code(save).
valid_code(save(File)) :- atom(File).
valid_code(show_and_save).
valid_code(show_save_and_run).
