:- module(
    piglog_reassembly,
    [logical_variable_map/2, partition_variable_ids/3, make_partition_result/13]
).

logical_variable_map(Goal, Variables) :-
    term_variables(Goal, Terms),
    number_variables(Terms, 1, Variables).

number_variables([], _, []).
number_variables([Variable|Variables], Number, [logical_variable(Id, Variable)|Mapped]) :-
    format(atom(Id), 'v~d', [Number]),
    Next is Number + 1,
    number_variables(Variables, Next, Mapped).

partition_variable_ids(Partitions, VariableMap, PartitionVariables) :-
    maplist(partition_variable_ids(VariableMap), Partitions, PartitionVariables).

partition_variable_ids(VariableMap, partition(Id, Goal, _, _, _),
                       piglog_partition_variables(Id, VariableIds)) :-
    term_variables(Goal, Variables),
    maplist(variable_id(VariableMap), Variables, VariableIds).

variable_id(VariableMap, Variable, Id) :-
    member(logical_variable(Id, MappedVariable), VariableMap),
    MappedVariable == Variable.

make_partition_result(
    ResultId,
    PartitionId,
    ParentEnvironmentId,
    BranchId,
    AnswerId,
    Bindings,
    Constraints,
    PartialTerms,
    StreamOutputs,
    Status,
    Provenance,
    VerificationDependencies,
    Result
) :-
    ( memberchk(Status, [confirmed, provisional, failed, cancelled, rejected]) ->
        Result = piglog_partition_result(
            ResultId,
            PartitionId,
            ParentEnvironmentId,
            BranchId,
            AnswerId,
            Bindings,
            Constraints,
            PartialTerms,
            StreamOutputs,
            Status,
            Provenance,
            VerificationDependencies
        )
    ; domain_error(piglog_partition_result_status, Status)
    ).
