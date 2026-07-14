:- module(example_pipeline, [produce_consume/2]).

produce_consume(Input, Output) :-
    Intermediate is Input + 1,
    Output is Intermediate * 3.
