:- begin_tests(piglog_gates).

:- use_module('../prolog/piglog').

test(closed_gate_blocks,
     [ setup(register_gate_fixture),
       cleanup(unregister_gate_fixture),
       throws(error(permission_error(run, piglog_gate, secret_gate), _))
     ]) :-
    piglog(user:gated_secret(_), [answers(first)]).

test(unlocked_gate_runs,
     [ setup(register_gate_fixture),
       cleanup(unregister_gate_fixture)
     ]) :-
    piglog_unlock(secret_gate),
    once(piglog(user:gated_secret(X), [answers(first)])),
    assertion(X == 42).

register_gate_fixture :-
    assertz((user:piglog_execution_gate(gated_secret/1, unlocked_by(secret_gate)))),
    assertz((user:gated_secret(42))).

unregister_gate_fixture :-
    retractall(user:piglog_execution_gate(gated_secret/1, unlocked_by(secret_gate))),
    retractall(user:gated_secret(_)),
    retractall(piglog_gates:piglog_gate_state(secret_gate, _)).

:- end_tests(piglog_gates).
