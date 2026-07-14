:- module(example_secure_learning, [reveal_answer/2, private_data/2]).

:- multifile piglog_execution_gate/2.
piglog_execution_gate(reveal_answer/2, unlocked_by(answer_requested)).
piglog_execution_gate(private_data/2, unlocked_by(authenticated_user)).

reveal_answer(QuestionId, Answer) :-
    QuestionId = q1,
    Answer = 42.

private_data(alice, token_abc).
