:- module(piglog_cost, [partition_cost/2, failure_probability/2]).

partition_cost(partition(_Id, Goal, _Req, _Prod, _), Cost) :-
    functor(Goal, Name, Arity),
    ( clause(_Module:piglog_cost(Name/Arity, Level), true) ->
        map_cost(Level, Cost)
    ; Cost = medium
    ).

failure_probability(partition(_Id, Goal, _Req, _Prod, _), Probability) :-
    functor(Goal, Name, Arity),
    ( clause(_Module:piglog_failure_probability(Name/Arity, P), true),
      number(P),
      P >= 0.0,
      P =< 1.0 ->
        Probability = P
    ; Probability = 0.10
    ).

map_cost(low, 1.0).
map_cost(medium, 3.0).
map_cost(high, 9.0).
