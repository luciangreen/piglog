:- module(piglog_partition, [build_partitions/2]).

build_partitions(Goal, Partitions) :-
    strip_module(Goal, _, PlainGoal),
    conjunction_to_list(PlainGoal, Calls),
    maplist(call_partition, Calls, Partitions).

call_partition(Call, partition(Id, Call, Requires, Produces, Readiness)) :-
    gensym(piglet_, Id),
    term_variables(Call, Vars),
    Requires = Vars,
    Produces = Vars,
    readiness_for_call(Call, Readiness).

readiness_for_call(_Call, 5).

conjunction_to_list((A, B), Calls) :-
    !,
    conjunction_to_list(A, Left),
    conjunction_to_list(B, Right),
    append(Left, Right, Calls).
conjunction_to_list(true, []) :- !.
conjunction_to_list(Call, [Call]).
