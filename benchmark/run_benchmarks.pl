:- module(benchmarks, [run_benchmarks/0]).

:- use_module('../prolog/piglog').

run_benchmarks :-
    Benchmarks = [
        bench(small_goal, member(_X, [1,2,3])),
        bench(independent_expensive, expensive_pair(_Y)),
        bench(failure_prone_guard, guarded(2)),
        bench(dependency_chain, dependency_chain(7, _Out))
    ],
    forall(member(bench(Name, Goal), Benchmarks), run_case(Name, Goal)).

run_case(Name, Goal) :-
    statistics(walltime, [_|_]),
    call(Goal),
    statistics(walltime, [_Elapsed, Millis]),
    format('benchmark(~w, wall_ms(~w)).~n', [Name, Millis]).

expensive_pair(Y) :-
    fib(20, A),
    fib(21, B),
    Y is A + B.

fib(0, 0) :- !.
fib(1, 1) :- !.
fib(N, F) :-
    N1 is N - 1,
    N2 is N - 2,
    fib(N1, F1),
    fib(N2, F2),
    F is F1 + F2.

guarded(N) :-
    integer(N),
    N > 0,
    N < 10.

dependency_chain(In, Out) :-
    A is In + 1,
    B is A * 2,
    Out is B - 3.
