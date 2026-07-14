:- begin_tests(piglog_converter).

:- use_module('../prolog/piglog').

chain(A, C) :-
    B is A + 1,
    C is B * 2.

test(partitions_visible) :-
    piglog_convert((A is 2 + 1, _C is A * 2), [], Generated),
    Generated.partitions \= [],
    Generated.dependencies \= [].

test(source_hash_in_generated_terms) :-
    piglog_convert(chain(3, _C), [code(return(Code))], _Generated),
    memberchk((:- piglog_source_hash(_)), Code).

:- end_tests(piglog_converter).
