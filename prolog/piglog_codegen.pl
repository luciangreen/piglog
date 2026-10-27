:- module(
    piglog_codegen,
    [build_generated_code_terms/3, show_generated_code/1, save_generated_code/2, default_output_file/3]
).

build_generated_code_terms(Model, Version, Terms) :-
    get_time(Now),
    format_time(atom(Date), '%FT%T%:z', Now),
    Hash = Model.hash,
    Options = Model.options,
    Partitions = Model.partitions,
    Dependencies = Model.dependencies,
    LogicalVariables = Model.logical_variables,
    PartitionVariables = Model.partition_variables,
    maplist(partition_term, Partitions, PartitionTerms),
    maplist(dep_term, Dependencies, DependencyTerms),
    maplist(logical_variable_term, LogicalVariables, LogicalVariableTerms),
    HeaderTerms = [
        (:- piglog_generated),
        (:- piglog_source_hash(Hash)),
        (:- piglog_version(Version)),
        (:- piglog_options(Options)),
        (:- piglog_generated_at(Date)),
        piglog_entry(Model.goal, Model.goal)
    ],
    append(HeaderTerms, PartitionTerms, WithPartitions),
    append(WithPartitions, DependencyTerms, WithDependencies),
    append(WithDependencies, LogicalVariableTerms, WithLogicalVariables),
    append(WithLogicalVariables, PartitionVariables, Terms).

partition_term(partition(Id, Goal, Requires, Produces, Readiness), piglog_partition(Id, Goal, Requires, Produces, Readiness)).
dep_term(Dep, Dep).
logical_variable_term(logical_variable(Id, _Variable), piglog_logical_variable(Id)).

show_generated_code(Terms) :-
    forall(member(Term, Terms), portray_clause(Term)).

save_generated_code(Terms, File) :-
    setup_call_cleanup(
        open(File, write, Stream, [encoding(utf8)]),
        forall(member(Term, Terms), portray_clause(Stream, Term)),
        close(Stream)
    ).

default_output_file(Goal, Options, File) :-
    ( get_dict(source_file, Options, SourceFile) ->
        file_base_name(SourceFile, Base),
        file_name_extension(Stem, _, Base),
        file_name_extension(Stem, 'piglog.pl', File)
    ; strip_module(Goal, _, PlainGoal),
      functor(PlainGoal, Name, _),
      format(atom(File), '~w.piglog.pl', [Name])
    ).
