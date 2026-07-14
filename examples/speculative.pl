:- module(example_speculative, [estimate_label/2]).

:- dynamic piglog_prediction/6.
piglog_prediction(estimate_label/2, likely, 0.80, source(heuristic), [known_input], verify_estimate).

estimate_label(Input, likely) :-
    atom(Input),
    atom_length(Input, Len),
    Len > 3.
