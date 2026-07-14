:- module(
    piglog_trace,
    [trace_event/5, emit_trace/2]
).

trace_event(Options, EventType, Details, EventsIn, EventsOut) :-
    get_time(Time),
    Event = piglog_event(Time, EventType, Details),
    ( trace_enabled(Options) ->
        EventsOut = [Event | EventsIn]
    ; EventsOut = EventsIn
    ).

emit_trace(Options, Events) :-
    ( Options.trace = terms(Var) ->
        reverse(Events, Ordered),
        Var = Ordered
    ; print_trace_if_needed(Options.trace, Events)
    ).

trace_enabled(Options) :-
    Options.trace \== false.

print_trace_if_needed(false, _) :- !.
print_trace_if_needed(_, Events) :-
    reverse(Events, Ordered),
    forall(member(Event, Ordered), portray_clause(Event)).
