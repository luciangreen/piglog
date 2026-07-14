:- module(
    piglog_cache,
    [cached_generated/3, put_generated_cache/3, piglog_clear_cache/0, piglog_clear_profile/0]
).

:- dynamic piglog_generated_cache/3.
:- dynamic piglog_profile_cache/2.

cached_generated(Hash, OptionsKey, Generated) :-
    piglog_generated_cache(Hash, OptionsKey, Generated).

put_generated_cache(Hash, OptionsKey, Generated) :-
    retractall(piglog_generated_cache(Hash, OptionsKey, _)),
    asserta(piglog_generated_cache(Hash, OptionsKey, Generated)).

piglog_clear_cache :-
    retractall(piglog_generated_cache(_, _, _)).

piglog_clear_profile :-
    retractall(piglog_profile_cache(_, _)).
