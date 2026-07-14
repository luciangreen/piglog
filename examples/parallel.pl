:- module(example_parallel, [pair_sum/3]).

pair_sum(A, B, Sum) :-
    number(A),
    number(B),
    Sum is A + B.
