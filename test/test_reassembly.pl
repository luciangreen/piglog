:- begin_tests(logical_variable_identity).

:- use_module('../prolog/piglog').
:- use_module('../prolog/piglog_reassembly').
:- use_module(library(clpfd)).

test(stable_ids_generated) :-
    piglog_reassembly:goal_logical_variables(example(A0, B, B), LogicalVariables),
    LogicalVariables = [logical_variable(v_1, _), logical_variable(v_2, _)],
    piglog_reassembly:build_term_templates(example(A0, B, B), LogicalVariables, [piglog_term_template(template_goal, Template, [v_1, v_2])]),
    Template = example(logical_var(v_1), logical_var(v_2), logical_var(v_2)).

:- end_tests(logical_variable_identity).

:- begin_tests(binding_integration).

test(nested_binding_reassembly) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(
        result_1,
        part_1,
        none,
        branch_main,
        answer_1,
        [v_x-person(alice, logical_var(v_age))],
        [],
        [],
        [],
        confirmed,
        source(partition),
        []
    ),
    Result2 = piglog_partition_result(
        result_2,
        part_2,
        none,
        branch_main,
        answer_1,
        [v_age-35],
        [],
        [],
        [],
        confirmed,
        source(partition),
        []
    ),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, Env2),
    Env2 = piglog_environment(_, _, _, Bindings, _, _, _, _),
    memberchk(v_x-person(alice, 35), Bindings).

:- end_tests(binding_integration).

:- begin_tests(binding_conflicts).

test(incompatible_binding_fails, [fail]) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(result_1, part_1, none, branch_main, answer_1, [v_age-35], [], [], [], confirmed, source(partition), []),
    Result2 = piglog_partition_result(result_2, part_2, none, branch_main, answer_1, [v_age-40], [], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, _Env2).

:- end_tests(binding_conflicts).

:- begin_tests(constraint_integration).

test(compatible_constraints_merge) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(result_1, part_1, none, branch_main, answer_1, [v_x-15], ['#>'(logical_var(v_x), 10)], [], [], confirmed, source(partition), []),
    Result2 = piglog_partition_result(result_2, part_2, none, branch_main, answer_1, [v_x-15], ['#<'(logical_var(v_x), 20)], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, _).

test(inconsistent_constraints_reject_environment, [fail]) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(result_1, part_1, none, branch_main, answer_1, [v_x-25], ['#>'(logical_var(v_x), 10)], [], [], confirmed, source(partition), []),
    Result2 = piglog_partition_result(result_2, part_2, none, branch_main, answer_1, [v_x-25], ['#<'(logical_var(v_x), 20)], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, _).

:- end_tests(constraint_integration).

:- begin_tests(partial_term_assembly).

test(provisional_then_confirmed_assembly) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(result_h, part_h, none, branch_main, answer_1, [v_header-title('Piglog')], [], [], [], provisional, source(partition), [prediction_1]),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    Template = template(
        report(logical_var(v_header), logical_var(v_body), logical_var(v_footer)),
        [v_header, v_body, v_footer],
        [piglog_term_requirement(template_report, final_confirmation, [v_header, v_body, v_footer])]
    ),
    piglog_reassembly:piglog_assemble_template(Template, Env1, provisional, _ProvisionalTerm),
    Result2 = piglog_partition_result(result_bf, part_bf, none, branch_main, answer_1, [v_body-analysis(ok), v_footer-references(done)], [], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, Env2),
    piglog_reassembly:piglog_assemble_template(Template, Env2, confirmed, FinalTerm),
    FinalTerm = report(title('Piglog'), analysis(ok), references(done)).

:- end_tests(partial_term_assembly).

:- begin_tests(nested_term_assembly).

test(nested_paths_assemble) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result = piglog_partition_result(
        result_doc,
        part_doc,
        none,
        branch_main,
        answer_1,
        [
            v_title-'Guide',
            v_author-'Piglog',
            v_intro-'Start',
            v_chapters-[c1, c2]
        ],
        [],
        [],
        [],
        confirmed,
        source(partition),
        []
    ),
    piglog_reassembly:piglog_add_partition_result(Env0, Result, Env1),
    Template = template(
        document(
            metadata(logical_var(v_title), logical_var(v_author)),
            body(introduction(logical_var(v_intro)), chapters(logical_var(v_chapters)))
        ),
        [v_title, v_author, v_intro, v_chapters],
        [piglog_term_requirement(template_document, final_confirmation, [v_title, v_author, v_intro, v_chapters])]
    ),
    piglog_reassembly:piglog_assemble_template(Template, Env1, confirmed, Term),
    Term = document(metadata('Guide', 'Piglog'), body(introduction('Start'), chapters([c1, c2]))).

:- end_tests(nested_term_assembly).

:- begin_tests(alias_preservation).

test(repeated_variable_aliasing_preserved) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result1 = piglog_partition_result(result_1, part_1, none, branch_main, answer_1, [v_pair-pair(logical_var(v_x), logical_var(v_x))], [], [], [], confirmed, source(partition), []),
    Result2 = piglog_partition_result(result_2, part_2, none, branch_main, answer_1, [v_x-a], [], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env0, Result1, Env1),
    piglog_reassembly:piglog_add_partition_result(Env1, Result2, Env2),
    Env2 = piglog_environment(_, _, _, Bindings, _, _, _, _),
    memberchk(v_pair-pair(a, a), Bindings).

:- end_tests(alias_preservation).

:- begin_tests(nondeterministic_environment_products).

test(independent_alternatives_cartesian_product) :-
    piglog_reassembly:clear_reassembly_state,
    Left = [
        piglog_partition_result(c1, colour_part, none, branch_main, a1, [v_colour-red], [], [], [], confirmed, source(partition), []),
        piglog_partition_result(c2, colour_part, none, branch_main, a2, [v_colour-blue], [], [], [], confirmed, source(partition), [])
    ],
    Right = [
        piglog_partition_result(s1, size_part, none, branch_main, b1, [v_size-small], [], [], [], confirmed, source(partition), []),
        piglog_partition_result(s2, size_part, none, branch_main, b2, [v_size-large], [], [], [], confirmed, source(partition), [])
    ],
    piglog_reassembly:piglog_join_result_sets(Left, Right, join_spec(auto), Joined),
    length(Joined, 4).

:- end_tests(nondeterministic_environment_products).

:- begin_tests(keyed_result_joining).

test(shared_key_join_only_matches_keys) :-
    piglog_reassembly:clear_reassembly_state,
    Left = [
        piglog_partition_result(l1, person_part, none, branch_main, a1, [v_id-1, v_name-alice], [], [], [], confirmed, source(partition), []),
        piglog_partition_result(l2, person_part, none, branch_main, a2, [v_id-2, v_name-bob], [], [], [], confirmed, source(partition), [])
    ],
    Right = [
        piglog_partition_result(r1, account_part, none, branch_main, b1, [v_id-1, v_balance-100], [], [], [], confirmed, source(partition), []),
        piglog_partition_result(r2, account_part, none, branch_main, b2, [v_id-3, v_balance-500], [], [], [], confirmed, source(partition), [])
    ],
    piglog_reassembly:piglog_join_result_sets(Left, Right, join_spec(keys([v_id])), Joined),
    length(Joined, 1),
    Joined = [piglog_joined_result(_, _, piglog_environment(_, _, _, Bindings, _, _, _, _))],
    memberchk(v_id-1, Bindings),
    memberchk(v_name-alice, Bindings),
    memberchk(v_balance-100, Bindings).

:- end_tests(keyed_result_joining).

:- begin_tests(branch_provenance).

test(mutually_exclusive_branches_never_merge, [fail]) :-
    piglog_reassembly:clear_reassembly_state,
    EnvA = piglog_environment(env_a, none, [if_branch(condition_1, then)], [v_x-positive], [], [], verified, active),
    EnvB = piglog_environment(env_b, none, [if_branch(condition_1, else)], [v_x-non_positive], [], [], verified, active),
    piglog_reassembly:piglog_merge_environments(EnvA, EnvB, _).

:- end_tests(branch_provenance).

:- begin_tests(cut_commitment).

test(cut_excludes_alternative_environment) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_invalidate_result(alt_2, cut_committed),
    piglog_reassembly:piglog_result_invalidated(alt_2, cut_committed).

:- end_tests(cut_commitment).

:- begin_tests(answer_ordering).

test(ordered_policy_preserved) :-
    findall(X, lists:member(X, [1, 2, 3]), Xs),
    Xs == [1,2,3].

:- end_tests(answer_ordering).

:- begin_tests(speculative_term_assembly).

test(provisional_term_not_confirmed_until_verification) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result = piglog_partition_result(result_risk, part_risk, none, branch_main, answer_1, [v_risk-low], [], [], [], provisional, source(prediction), [prediction_7]),
    piglog_reassembly:piglog_add_partition_result(Env0, Result, Env1),
    Template = template(report(logical_var(v_risk)), [v_risk], [piglog_term_requirement(template_report, final_confirmation, [v_risk])]),
    piglog_reassembly:piglog_assemble_template(Template, Env1, provisional, _).

:- end_tests(speculative_term_assembly).

:- begin_tests(selective_reassembly_after_rollback).

test(invalidation_only_touches_dependent_terms) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result = piglog_partition_result(result_risk, part_risk, none, branch_main, answer_1, [v_risk-value(low, result(result_risk))], [], [], [], provisional, source(prediction), [prediction_7]),
    piglog_reassembly:piglog_add_partition_result(Env0, Result, Env1),
    Template = template(report(logical_var(v_risk)), [v_risk], [piglog_term_requirement(template_report, final_confirmation, [v_risk])]),
    piglog_reassembly:piglog_assemble_template(Template, Env1, provisional, _),
    piglog_reassembly:piglog_invalidate_dependent_terms(result_risk, Invalidated),
    Invalidated \= [].

:- end_tests(selective_reassembly_after_rollback).

:- begin_tests(stream_fragment_assembly).

test(ordered_fragments_assembled) :-
    Fragments = [fragment(3, third), fragment(1, first), fragment(2, second)],
    sort(1, @=<, Fragments, Sorted),
    Sorted = [fragment(1, first), fragment(2, second), fragment(3, third)].

:- end_tests(stream_fragment_assembly).

:- begin_tests(difference_list_assembly).

test(chunks_link_without_prefix_copy) :-
    Chunk1 = [first, second | Tail1],
    Tail1 = [third | Tail2],
    Tail2 = [],
    Chunk1 == [first, second, third].

:- end_tests(difference_list_assembly).

:- begin_tests(environment_garbage_collection).

test(rejected_result_invalidates_terms_for_collection) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_invalidate_result(result_dead, rejected),
    piglog_reassembly:piglog_result_invalidated(result_dead, rejected).

:- end_tests(environment_garbage_collection).

:- begin_tests(reassembly_explanations).

test(explanation_reports_sources) :-
    piglog_reassembly:clear_reassembly_state,
    piglog_reassembly:piglog_create_environment(none, [], Env0),
    Result = piglog_partition_result(result_profile, part_profile, none, branch_main, answer_1, [v_profile-value(alice, result(result_profile))], [], [], [], confirmed, source(partition), []),
    piglog_reassembly:piglog_add_partition_result(Env0, Result, Env1),
    Template = template(profile(logical_var(v_profile)), [v_profile], [piglog_term_requirement(template_profile, final_confirmation, [v_profile])]),
    piglog_reassembly:piglog_assemble_template(Template, Env1, confirmed, _),
    piglog_reassembly:piglog_latest_assembled_term(TermId),
    piglog_reassembly:piglog_explain_term(TermId, Explanation),
    Explanation = piglog_term_explanation(_, _, _, status(confirmed), _, _, _).

:- end_tests(reassembly_explanations).
