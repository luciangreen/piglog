:- module(example_failure_first, [validate_even/1]).

validate_even(Value) :-
    integer(Value),
    0 is Value mod 2.
