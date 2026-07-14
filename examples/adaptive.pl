:- module(example_adaptive, [classify/2]).

classify(Number, positive) :-
    Number > 0.
classify(0, zero).
classify(Number, negative) :-
    Number < 0.
