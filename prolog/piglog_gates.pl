:- module(
    piglog_gates,
    [piglog_unlock/1, piglog_lock/1, enforce_gate_for_goal/1, goal_gate/2]
).

:- dynamic piglog_gate_state/2.

piglog_unlock(Gate) :-
    must_be(nonvar, Gate),
    retractall(piglog_gate_state(Gate, _)),
    asserta(piglog_gate_state(Gate, unlocked)).

piglog_lock(Gate) :-
    must_be(nonvar, Gate),
    retractall(piglog_gate_state(Gate, _)),
    asserta(piglog_gate_state(Gate, locked)).

enforce_gate_for_goal(Goal) :-
    ( goal_gate(Goal, Gate),
      \+ gate_open(Gate) ->
        throw(error(permission_error(run, piglog_gate, Gate), Goal))
    ; true
    ).

goal_gate(Goal, Gate) :-
    strip_module(Goal, _, PlainGoal),
    functor(PlainGoal, Name, Arity),
    Pred = Name/Arity,
    current_predicate(Module:piglog_execution_gate/2),
    Module:piglog_execution_gate(Pred, unlocked_by(Gate)).
goal_gate(Goal, Gate) :-
    strip_module(Goal, _, PlainGoal),
    functor(PlainGoal, Name, Arity),
    Pred = Name/Arity,
    current_predicate(Module:piglog_execution_gate/3),
    Module:piglog_execution_gate(Pred, unlocked_by(Gate), _Options).

gate_open(Gate) :-
    piglog_gate_state(Gate, unlocked),
    !.
