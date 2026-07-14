:- begin_tests(piglog_api).

:- use_module('../prolog/piglog').

sample_goal(X, Y) :-
    member(X, [1,2]),
    Y is X + 1.

test(default_call, [nondet]) :-
    piglog(sample_goal(1, 2)).

test(convert_returns_terms) :-
    piglog_convert(sample_goal(_X, _Y), [code(return(Code))], Generated),
    is_list(Code),
    is_dict(Generated).

test(show_and_save, [setup(delete_if_exists('sample_goal.piglog.pl')), cleanup(delete_if_exists('sample_goal.piglog.pl'))]) :-
    piglog(sample_goal(_X, _Y), [answers(first), code(show_and_save)]),
    exists_file('sample_goal.piglog.pl').

delete_if_exists(File) :-
    ( exists_file(File) -> delete_file(File) ; true ).

:- end_tests(piglog_api).
