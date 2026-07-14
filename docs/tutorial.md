# Tutorial

1. Define a predicate:

```prolog
my_algorithm(X, Y) :-
    member(X, [1,2,3]),
    Y is X * 2.
```

2. Run with Piglog:

```prolog
?- piglog(my_algorithm(X, Y), [trace(summary), code(show)]).
```

3. Save generated code:

```prolog
?- piglog(my_algorithm(X, Y), [code(save('my_algorithm.piglog.pl'))]).
```

4. Capture trace terms:

```prolog
?- piglog(my_algorithm(X, Y), [trace(terms(Events))]).
```
