:- module(example_sequential, [calculate/2]).

calculate(Input, Output) :-
    number(Input),
    Output is Input * 2.
