:- begin_tests(piglog_scheduler).

:- use_module('../prolog/piglog').

value(1).
value(2).

test(answer_first) :-
    piglog(value(X), [answers(first)]),
    X == 1.

test(answer_ordered) :-
    findall(X, piglog(value(X), [answers(ordered)]), Xs),
    Xs == [1, 2].

test(trace_terms_collects) :-
    piglog(value(_), [answers(first), trace(terms(Events))]),
    Events \= [].

:- end_tests(piglog_scheduler).
