:- module(piglog_reader, [load_source_file/1, ensure_callable_goal/1, source_hash_for_goal/2]).

load_source_file(File) :-
    must_be(atom, File),
    exists_file(File),
    load_files(File, [if(changed)]).

ensure_callable_goal(Goal) :-
    must_be(callable, Goal),
    strip_module(Goal, Module, PlainGoal),
    functor(PlainGoal, Name, Arity),
    ( current_predicate(Module:Name/Arity) ->
        true
    ; existence_error(predicate, Name/Arity)
    ).

source_hash_for_goal(Goal, Hash) :-
    callable(Goal),
    strip_module(Goal, Module, PlainGoal),
    functor(PlainGoal, Name, Arity),
    ( predicate_property(Module:PlainGoal, file(File)),
      exists_file(File) ->
        setup_call_cleanup(
            open(File, read, Stream, [type(binary)]),
            read_stream_to_codes(Stream, Codes),
            close(Stream)
        ),
        term_hash(file(File, Codes), Hash)
    ; term_hash(predicate(Module:Name/Arity), Hash)
    ).
