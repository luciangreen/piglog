:- begin_tests(piglog_reassembly).

:- use_module('../prolog/piglog').
:- use_module('../prolog/piglog_reassembly').

test(stable_variable_ids_are_shared_across_partitions) :-
    once(piglog_convert((A is 1, _B is A + 1), [], Generated)),
    Generated.logical_variables = [
        logical_variable(v1, _),
        logical_variable(v2, _)
    ],
    Generated.partition_variables = [
        piglog_partition_variables(_, FirstIds),
        piglog_partition_variables(_, SecondIds)
    ],
    memberchk(v1, FirstIds),
    sort(SecondIds, [v1, v2]),
    memberchk(piglog_logical_variable(v1), Generated.code_terms),
    memberchk(piglog_logical_variable(v2), Generated.code_terms).

test(partition_result_record) :-
    make_partition_result(
        result_1,
        partition_1,
        env_1,
        branch_1,
        answer_1,
        [v1-value],
        [],
        [],
        [],
        confirmed,
        source(partition_1),
        [],
        Result
    ),
    Result = piglog_partition_result(
        result_1,
        partition_1,
        env_1,
        branch_1,
        answer_1,
        [v1-value],
        [],
        [],
        [],
        confirmed,
        source(partition_1),
        []
    ).

test(partition_result_rejects_unknown_status,
     [throws(error(domain_error(piglog_partition_result_status, unknown), _))]) :-
    make_partition_result(
        result_1, partition_1, env_1, branch_1, answer_1,
        [], [], [], [], unknown, source(partition_1), [], _
    ).

:- end_tests(piglog_reassembly).
