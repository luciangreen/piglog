:- module(piglog_purity, [classify_partition/2, pure_partition/1]).

classify_partition(partition(Id, Goal, _, _, _), piglog_purity(Id, Purity)) :-
    classify_goal(Goal, Purity).

pure_partition(piglog_purity(_, pure)).

classify_goal(Goal, Purity) :-
    strip_module(Goal, _, PlainGoal),
    functor(PlainGoal, Name, Arity),
    effect_builtin(Name/Arity),
    !,
    Purity = external_effect.
classify_goal(Goal, pure) :-
    strip_module(Goal, Module, PlainGoal),
    predicate_property(Module:PlainGoal, interpreted),
    !.
classify_goal(_Goal, unknown).

effect_builtin(write/1).
effect_builtin(format/2).
effect_builtin(read/1).
effect_builtin(open/3).
effect_builtin(close/1).
effect_builtin(asserta/1).
effect_builtin(assertz/1).
effect_builtin(retract/1).
effect_builtin(retractall/1).
effect_builtin(abolish/1).
effect_builtin(get_time/1).
effect_builtin(random/1).
effect_builtin(thread_send_message/2).
effect_builtin(shell/1).
effect_builtin(process_create/3).
