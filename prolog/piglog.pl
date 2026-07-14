:- module(
    piglog,
    [
        piglog/1,
        piglog/2,
        piglog_file/3,
        piglog_convert/3,
        piglog_run_generated/2,
        piglog_show_code/1,
        piglog_save_code/2,
        piglog_clear_cache/0,
        piglog_clear_profile/0,
        piglog_unlock/1,
        piglog_lock/1
    ]
).

:- use_module(piglog_options).
:- use_module(piglog_reader).
:- use_module(piglog_converter).
:- use_module(piglog_codegen).
:- use_module(piglog_scheduler).
:- use_module(piglog_cache, [cached_generated/3, put_generated_cache/3]).
:- use_module(piglog_gates, [enforce_gate_for_goal/1]).

:- meta_predicate piglog(0).
:- meta_predicate piglog(0, +).
:- meta_predicate piglog_file(+, 0, +).
:- meta_predicate piglog_convert(0, +, -).

piglog(Goal) :-
    piglog(Goal, []).

piglog(Goal, UserOptions) :-
    normalize_options(UserOptions, Goal, Options),
    once((
        piglog_convert(Goal, UserOptions, Generated),
        maybe_output_code(Generated, Options)
    )),
    piglog_run_generated(Generated, UserOptions).

piglog_file(File, Goal, UserOptions) :-
    load_source_file(File),
    normalize_options([source_file(File) | UserOptions], Goal, _),
    piglog(Goal, [source_file(File) | UserOptions]).

piglog_convert(Goal, UserOptions, Generated) :-
    normalize_options(UserOptions, Goal, Options),
    ensure_callable_goal(Goal),
    source_hash_for_goal(Goal, Hash),
    conversion_cache_key(Options, CacheKey),
    ( cached_generated(Hash, CacheKey, Cached) ->
        refresh_generated_goal(Cached, Goal, Generated)
    ; convert_goal(Goal, Options, Hash, Converted),
      put_generated_cache(Hash, CacheKey, Converted),
      Generated = Converted
    ),
    maybe_return_code(Generated, Options).

piglog_run_generated(Generated, UserOptions) :-
    Goal = Generated.goal,
    normalize_options(UserOptions, Goal, Options),
    enforce_gate_for_goal(Goal),
    run_generated(Generated, Options).

piglog_show_code(Generated) :-
    get_generated_terms(Generated, Terms),
    show_generated_code(Terms).

piglog_save_code(Generated, File) :-
    get_generated_terms(Generated, Terms),
    save_generated_code(Terms, File).

piglog_clear_cache :-
    piglog_cache:piglog_clear_cache.

piglog_clear_profile :-
    piglog_cache:piglog_clear_profile.

piglog_unlock(Gate) :-
    piglog_gates:piglog_unlock(Gate).

piglog_lock(Gate) :-
    piglog_gates:piglog_lock(Gate).

maybe_output_code(Generated, Options) :-
    Code = Options.code,
    maybe_show_code(Code, Generated),
    maybe_save_code(Code, Generated, Options).

maybe_show_code(show, Generated) :-
    !,
    piglog_show_code(Generated).
maybe_show_code(show_and_save, Generated) :-
    !,
    piglog_show_code(Generated).
maybe_show_code(show_save_and_run, Generated) :-
    !,
    piglog_show_code(Generated).
maybe_show_code(_, _).

maybe_save_code(save, Generated, Options) :-
    !,
    default_output_file(Generated.goal, Options, File),
    piglog_save_code(Generated, File).
maybe_save_code(save(File), Generated, _Options) :-
    !,
    piglog_save_code(Generated, File).
maybe_save_code(show_and_save, Generated, Options) :-
    !,
    default_output_file(Generated.goal, Options, File),
    piglog_save_code(Generated, File).
maybe_save_code(show_save_and_run, Generated, Options) :-
    !,
    default_output_file(Generated.goal, Options, File),
    piglog_save_code(Generated, File).
maybe_save_code(_, _, _).

maybe_return_code(Generated, Options) :-
    ( Options.code = return(Var) ->
        get_generated_terms(Generated, Var)
    ; true
    ).

get_generated_terms(Generated, Terms) :-
    ( is_dict(Generated),
      get_dict(code_terms, Generated, Terms) ->
        true
    ; Terms = Generated
    ).

refresh_generated_goal(Cached, Goal, Generated) :-
    copy_term(Cached, Fresh),
    Generated = Fresh.put(goal, Goal).
