:- module(
    piglog_reassembly,
    [
        goal_logical_variables/2,
        build_term_templates/3,
        default_term_requirements/2,
        piglog_create_environment/3,
        piglog_add_partition_result/3,
        piglog_merge_environments/3,
        piglog_join_result_sets/4,
        piglog_assemble_template/4,
        piglog_confirm_assembled_term/2,
        piglog_invalidate_result/2,
        piglog_invalidate_dependent_terms/2,
        piglog_explain_term/2,
        piglog_result_invalidated/2,
        piglog_latest_assembled_term/1,
        clear_reassembly_state/0
    ]
).

:- use_module(library(gensym)).
:- use_module(library(lists)).
:- use_module(library(clpfd)).

:- dynamic invalidated_result/2.
:- dynamic assembled_term/6.
:- dynamic assembled_term_component/2.

clear_reassembly_state :-
    retractall(invalidated_result(_, _)),
    retractall(assembled_term(_, _, _, _, _, _)),
    retractall(assembled_term_component(_, _)),
    reset_gensym(env_),
    reset_gensym(term_).

goal_logical_variables(Goal, LogicalVariables) :-
    term_variables(Goal, Variables),
    number_variables(Variables, 1, LogicalVariables).

number_variables([], _, []).
number_variables([Var | Rest], N, [logical_variable(Id, Var) | Out]) :-
    format(atom(Id), 'v_~d', [N]),
    N2 is N + 1,
    number_variables(Rest, N2, Out).

build_term_templates(Goal, LogicalVariables, Templates) :-
    logical_var_map(LogicalVariables, IdMap),
    replace_vars_with_logical_ids(Goal, IdMap, Template),
    maplist(logical_variable_id, LogicalVariables, Required),
    Templates = [piglog_term_template(template_goal, Template, Required)].

logical_variable_id(logical_variable(Id, _), Id).

default_term_requirements(Templates, Requirements) :-
    findall(
        piglog_term_requirement(TemplateId, provisional_construction, Provisional),
        (
            member(piglog_term_template(TemplateId, Template0, Vars), Templates),
            nonvar(Template0),
            provisional_vars(Vars, Provisional)
        ),
        ProvisionalRequirements
    ),
    findall(
        piglog_term_requirement(TemplateId, final_confirmation, Vars),
        (
            member(piglog_term_template(TemplateId, _Template1, Vars), Templates)
        ),
        FinalRequirements
    ),
    append(ProvisionalRequirements, FinalRequirements, Requirements).

provisional_vars([First | _], [First]) :- !.
provisional_vars([], []).

piglog_create_environment(ParentEnvironment, BranchPath, Environment) :-
    gensym(env_, EnvironmentId),
    environment_id(ParentEnvironment, ParentEnvironmentId),
    Environment = piglog_environment(
        EnvironmentId,
        ParentEnvironmentId,
        BranchPath,
        [],
        [],
        [],
        verified,
        active
    ).

environment_id(none, none) :- !.
environment_id(piglog_environment(EnvironmentId, _, _, _, _, _, _, _), EnvironmentId) :- !.
environment_id(ParentEnvironmentId, ParentEnvironmentId).

piglog_add_partition_result(
    Environment,
    piglog_partition_result(
        _ResultId,
        _PartitionId,
        ParentEnvironmentId,
        BranchId,
        _AnswerId,
        Bindings,
        Constraints,
        PartialTerms,
        StreamOutputs,
        ResultStatus,
        _Provenance,
        VerificationDependencies
    ),
    NewEnvironment
) :-
    Environment = piglog_environment(
        EnvironmentId,
        ExistingParentEnvironmentId,
        BranchPath,
        ExistingBindings,
        ExistingConstraints,
        ExistingTermFragments,
        ExistingVerificationState,
        ExistingStatus
    ),
    must_match_parent(EnvironmentId, ExistingParentEnvironmentId, ParentEnvironmentId),
    must_match_branch_path(BranchPath, BranchId, NewBranchPath),
    merge_bindings_and_constraints(
        ExistingBindings,
        ExistingConstraints,
        Bindings,
        Constraints,
        MergedBindings,
        MergedConstraints
    ),
    append(ExistingTermFragments, PartialTerms, WithPartials),
    append(WithPartials, [stream_outputs(StreamOutputs)], NewTermFragments),
    merge_verification_state(ExistingVerificationState, ResultStatus, VerificationDependencies, NewVerificationState),
    merge_environment_status(ExistingStatus, ResultStatus, NewStatus),
    gensym(env_, NewEnvironmentId),
    NewEnvironment = piglog_environment(
        NewEnvironmentId,
        EnvironmentId,
        NewBranchPath,
        MergedBindings,
        MergedConstraints,
        NewTermFragments,
        NewVerificationState,
        NewStatus
    ).

must_match_parent(_, ExistingParent, Parent) :-
    ( var(Parent) ; Parent == ExistingParent ; Parent == none ),
    !.
must_match_parent(EnvironmentId, _ExistingParent, Parent) :-
    Parent == EnvironmentId.

must_match_branch_path([], BranchId, [BranchId]) :-
    nonvar(BranchId),
    BranchId \== none,
    !.
must_match_branch_path(Path, none, Path) :- !.
must_match_branch_path(Path, BranchId, Path) :-
    memberchk(BranchId, Path),
    !.
must_match_branch_path(Path, BranchId, NewPath) :-
    append(Path, [BranchId], NewPath).

merge_verification_state(provisional, confirmed, [], verified) :- !.
merge_verification_state(provisional, _, _, provisional) :- !.
merge_verification_state(_, provisional, _, provisional) :- !.
merge_verification_state(_, _, VerificationDependencies, provisional) :-
    VerificationDependencies \== [],
    !.
merge_verification_state(_, _, _, verified).

merge_environment_status(_, failed, failed) :- !.
merge_environment_status(_, rejected, rejected) :- !.
merge_environment_status(_, cancelled, cancelled) :- !.
merge_environment_status(_, provisional, provisional) :- !.
merge_environment_status(Status, _, Status).

piglog_merge_environments(
    piglog_environment(
        LeftEnvironmentId,
        LeftParentEnvironmentId,
        LeftBranchPath,
        LeftBindings,
        LeftConstraints,
        LeftTermFragments,
        LeftVerificationState,
        LeftStatus
    ),
    piglog_environment(
        RightEnvironmentId,
        RightParentEnvironmentId,
        RightBranchPath,
        RightBindings,
        RightConstraints,
        RightTermFragments,
        RightVerificationState,
        RightStatus
    ),
    piglog_environment(
        MergedEnvironmentId,
        ParentEnvironmentId,
        MergedBranchPath,
        MergedBindings,
        MergedConstraints,
        MergedTermFragments,
        MergedVerificationState,
        MergedStatus
    )
) :-
    parent_environment_for_merge(
        LeftEnvironmentId,
        LeftParentEnvironmentId,
        RightEnvironmentId,
        RightParentEnvironmentId,
        ParentEnvironmentId
    ),
    branch_paths_compatible(LeftBranchPath, RightBranchPath),
    merge_branch_paths(LeftBranchPath, RightBranchPath, MergedBranchPath),
    merge_bindings_and_constraints(
        LeftBindings,
        LeftConstraints,
        RightBindings,
        RightConstraints,
        MergedBindings,
        MergedConstraints
    ),
    append(LeftTermFragments, RightTermFragments, MergedTermFragments),
    merge_two_verification_states(LeftVerificationState, RightVerificationState, MergedVerificationState),
    merge_two_statuses(LeftStatus, RightStatus, MergedStatus),
    gensym(env_, MergedEnvironmentId).

parent_environment_for_merge(LeftId, LeftParentId, _RightId, RightParentId, ParentEnvironmentId) :-
    ( LeftParentId == RightParentId ->
        ParentEnvironmentId = LeftParentId
    ; RightParentId == LeftId ->
        ParentEnvironmentId = LeftId
    ; LeftParentId == none ->
        ParentEnvironmentId = RightParentId
    ; RightParentId == none ->
        ParentEnvironmentId = LeftParentId
    ; ParentEnvironmentId = LeftParentId
    ).

merge_branch_paths(Left, Right, Merged) :-
    append(Left, Right, Combined),
    list_to_set(Combined, Merged).

branch_paths_compatible(Left, Right) :-
    \+ (
        member(if_branch(Key, LeftSide), Left),
        member(if_branch(Key, RightSide), Right),
        LeftSide \== RightSide
    ).

merge_two_verification_states(verified, verified, verified) :- !.
merge_two_verification_states(_, _, provisional).

merge_two_statuses(failed, _, failed) :- !.
merge_two_statuses(_, failed, failed) :- !.
merge_two_statuses(rejected, _, rejected) :- !.
merge_two_statuses(_, rejected, rejected) :- !.
merge_two_statuses(cancelled, _, cancelled) :- !.
merge_two_statuses(_, cancelled, cancelled) :- !.
merge_two_statuses(provisional, _, provisional) :- !.
merge_two_statuses(_, provisional, provisional) :- !.
merge_two_statuses(active, active, active) :- !.
merge_two_statuses(confirmed, confirmed, confirmed) :- !.
merge_two_statuses(_, _, active).

piglog_join_result_sets(LeftResults, RightResults, JoinSpec, JoinedResults) :-
    findall(
        Joined,
        joined_result(LeftResults, RightResults, JoinSpec, Joined),
        JoinedResults
    ).

joined_result(LeftResults, RightResults, JoinSpec, piglog_joined_result(LeftResultId, RightResultId, MergedEnvironment)) :-
    member(
        piglog_partition_result(
            LeftResultId,
            _LeftPartitionId,
            LeftParentEnvironmentId,
            LeftBranchId,
            _LeftAnswerId,
            LeftBindings,
            LeftConstraints,
            LeftPartialTerms,
            _LeftStreamOutputs,
            LeftStatus,
            _LeftProvenance,
            LeftVerificationDependencies
        ),
        LeftResults
    ),
    member(
        piglog_partition_result(
            RightResultId,
            _RightPartitionId,
            RightParentEnvironmentId,
            RightBranchId,
            _RightAnswerId,
            RightBindings,
            RightConstraints,
            RightPartialTerms,
            _RightStreamOutputs,
            RightStatus,
            _RightProvenance,
            RightVerificationDependencies
        ),
        RightResults
    ),
    parent_for_join(LeftParentEnvironmentId, RightParentEnvironmentId, ParentEnvironmentId),
    BaseEnvironment = piglog_environment(
        base_join,
        ParentEnvironmentId,
        [LeftBranchId, RightBranchId],
        [],
        [],
        [],
        verified,
        active
    ),
    piglog_add_partition_result(
        BaseEnvironment,
        piglog_partition_result(
            LeftResultId,
            left_join_partition,
            ParentEnvironmentId,
            LeftBranchId,
            left_answer,
            LeftBindings,
            LeftConstraints,
            LeftPartialTerms,
            [],
            LeftStatus,
            source(join_left),
            LeftVerificationDependencies
        ),
        LeftEnvironment
    ),
    piglog_add_partition_result(
        LeftEnvironment,
        piglog_partition_result(
            RightResultId,
            right_join_partition,
            ParentEnvironmentId,
            RightBranchId,
            right_answer,
            RightBindings,
            RightConstraints,
            RightPartialTerms,
            [],
            RightStatus,
            source(join_right),
            RightVerificationDependencies
        ),
        CombinedEnvironment
    ),
    join_spec_compatible(JoinSpec, CombinedEnvironment),
    MergedEnvironment = CombinedEnvironment.

parent_for_join(LeftParent, RightParent, LeftParent) :-
    LeftParent == RightParent,
    !.
parent_for_join(none, RightParent, RightParent) :- !.
parent_for_join(LeftParent, none, LeftParent) :- !.
parent_for_join(LeftParent, _RightParent, LeftParent).

join_spec_compatible(join_spec(keys(Keys)), Environment) :-
    !,
    Environment = piglog_environment(_, _, _, Bindings, _, _, _, _),
    forall(member(Key, Keys), memberchk(Key-_, Bindings)).
join_spec_compatible(_JoinSpec, _Environment).

piglog_assemble_template(TemplateId, Environment, AssemblyStatus, Term) :-
    template_for_assembly(TemplateId, Template, TemplateVariables, Requirements),
    Environment = piglog_environment(
        EnvironmentId,
        _ParentEnvironmentId,
        _BranchPath,
        Bindings,
        _Constraints,
        _TermFragments,
        VerificationState,
        _Status
    ),
    instantiate_template(Template, Bindings, Term),
    determine_assembly_status(TemplateVariables, Requirements, Bindings, VerificationState, AssemblyStatus),
    gensym(term_, TermId),
    dependency_list_for_template(TemplateVariables, Bindings, Dependencies),
    assertz(assembled_term(TermId, TemplateId, Term, EnvironmentId, AssemblyStatus, Dependencies)),
    forall(member(component(VariableId, ResultId), Dependencies), assertz(assembled_term_component(TermId, component(VariableId, ResultId)))).

template_for_assembly(TemplateId, Template, Variables, Requirements) :-
    nonvar(TemplateId),
    TemplateId = piglog_term_template(_InlineTemplateId, InlineTemplate, InlineVars),
    !,
    Template = InlineTemplate,
    Variables = InlineVars,
    Requirements = [piglog_term_requirement(inline, final_confirmation, InlineVars)].
template_for_assembly(
    template(Template, Variables, Requirements),
    Template,
    Variables,
    Requirements
) :-
    !.
template_for_assembly(TemplateId, _Template, _Variables, _Requirements) :-
    throw(error(existence_error(term_template, TemplateId), piglog_assemble_template/4)).

determine_assembly_status(TemplateVariables, Requirements, Bindings, VerificationState, confirmed) :-
    required_for_final_confirmation(TemplateVariables, Requirements, Required),
    all_variables_bound(Required, Bindings),
    VerificationState == verified,
    !.
determine_assembly_status(_TemplateVariables, _Requirements, _Bindings, _VerificationState, provisional).

required_for_final_confirmation(TemplateVariables, Requirements, Required) :-
    ( member(piglog_term_requirement(_TemplateId, final_confirmation, RequiredVars), Requirements) ->
        Required = RequiredVars
    ; Required = TemplateVariables
    ).

all_variables_bound([], _Bindings).
all_variables_bound([VariableId | Rest], Bindings) :-
    memberchk(VariableId-Value, Bindings),
    nonvar(Value),
    all_variables_bound(Rest, Bindings).

dependency_list_for_template([], _Bindings, []).
dependency_list_for_template([VariableId | Rest], Bindings, Dependencies) :-
    ( memberchk(VariableId-Value, Bindings),
      value_dependency_result(Value, ResultId) ->
        Dependencies = [component(VariableId, ResultId) | More]
    ; Dependencies = More
    ),
    dependency_list_for_template(Rest, Bindings, More).

value_dependency_result(value(_Value, result(ResultId)), ResultId) :- !.

piglog_confirm_assembled_term(TermId, ConfirmedTerm) :-
    assembled_term(TermId, TemplateId, Term, EnvironmentId, _AssemblyStatus, Dependencies),
    retractall(assembled_term(TermId, _, _, _, _, _)),
    assertz(assembled_term(TermId, TemplateId, Term, EnvironmentId, confirmed, Dependencies)),
    ConfirmedTerm = Term.

piglog_invalidate_result(ResultId, Reason) :-
    retractall(invalidated_result(ResultId, _)),
    assertz(invalidated_result(ResultId, Reason)).

piglog_invalidate_dependent_terms(ResultId, InvalidatedTermIds) :-
    findall(
        TermId,
        (
            assembled_term_component(TermId, component(_VariableId, ResultId)),
            assembled_term(TermId, _TemplateId, _Term, _EnvironmentId, Status, _Dependencies),
            Status \== invalidated
        ),
        TermIds
    ),
    list_to_set(TermIds, InvalidatedTermIds),
    forall(
        member(TermId, InvalidatedTermIds),
        invalidate_term_record(TermId, ResultId)
    ).

invalidate_term_record(TermId, ResultId) :-
    assembled_term(TermId, TemplateId, Term, EnvironmentId, _Status, Dependencies),
    retractall(assembled_term(TermId, _, _, _, _, _)),
    assertz(
        assembled_term(
            TermId,
            TemplateId,
            Term,
            EnvironmentId,
            invalidated,
            [invalidated_by(ResultId) | Dependencies]
        )
    ).

piglog_explain_term(TermId, Explanation) :-
    assembled_term(TermId, TemplateId, Term, EnvironmentId, Status, Dependencies),
    findall(component(VariableId, ResultId), assembled_term_component(TermId, component(VariableId, ResultId)), Components),
    Explanation = piglog_term_explanation(
        term_id(TermId),
        template(TemplateId),
        environment(EnvironmentId),
        status(Status),
        term(Term),
        components(Components),
        dependencies(Dependencies)
    ).

piglog_result_invalidated(ResultId, Reason) :-
    invalidated_result(ResultId, Reason).

piglog_latest_assembled_term(TermId) :-
    findall(Id, assembled_term(Id, _, _, _, _, _), TermIds),
    last(TermIds, TermId).

merge_bindings_and_constraints(
    LeftBindings,
    LeftConstraints,
    RightBindings,
    RightConstraints,
    MergedBindings,
    MergedConstraints
) :-
    append(LeftBindings, RightBindings, CombinedBindings),
    logical_ids_in_bindings(CombinedBindings, BindingIds),
    build_id_var_map(BindingIds, IdVarMap),
    apply_bindings(CombinedBindings, IdVarMap),
    append(LeftConstraints, RightConstraints, MergedConstraints),
    apply_constraints(MergedConstraints, IdVarMap),
    extract_bindings(BindingIds, IdVarMap, MergedBindings).

logical_ids_in_bindings(Bindings, SortedIds) :-
    findall(Id, member(Id-_, Bindings), DirectIds),
    findall(NestedId, (member(_-Value, Bindings), logical_var_occurrence(Value, NestedId)), NestedIds),
    append(DirectIds, NestedIds, AllIds),
    list_to_set(AllIds, SortedIds).

logical_var_occurrence(logical_var(Id), Id) :- !.
logical_var_occurrence(Term, Id) :-
    compound(Term),
    Term =.. [_Functor | Args],
    member(Arg, Args),
    logical_var_occurrence(Arg, Id).

build_id_var_map([], []).
build_id_var_map([Id | Rest], [Id-_Var | Out]) :-
    build_id_var_map(Rest, Out).

apply_bindings([], _IdVarMap).
apply_bindings([Id-ValueExpr | Rest], IdVarMap) :-
    lookup_id_var(IdVarMap, Id, Variable),
    instantiate_value_expression(ValueExpr, IdVarMap, ValueTerm),
    unify_value(Variable, ValueTerm),
    apply_bindings(Rest, IdVarMap).

apply_constraints([], _IdVarMap).
apply_constraints([ConstraintExpr | Rest], IdVarMap) :-
    instantiate_value_expression(ConstraintExpr, IdVarMap, Constraint),
    call(Constraint),
    apply_constraints(Rest, IdVarMap).

instantiate_value_expression(logical_var(Id), IdVarMap, Variable) :-
    !,
    lookup_id_var(IdVarMap, Id, Variable).
instantiate_value_expression(Term, IdVarMap, Instantiated) :-
    compound(Term),
    !,
    Term =.. [Functor | Args],
    maplist(instantiate_with_map(IdVarMap), Args, InstantiatedArgs),
    Instantiated =.. [Functor | InstantiatedArgs].
instantiate_value_expression(Term, _IdVarMap, Term).

instantiate_with_map(IdVarMap, In, Out) :-
    instantiate_value_expression(In, IdVarMap, Out).

unify_value(Variable, ValueTerm) :-
    term_policy(rational_trees),
    !,
    Variable = ValueTerm.
unify_value(Variable, ValueTerm) :-
    term_policy(occurs_check),
    !,
    unify_with_occurs_check(Variable, ValueTerm).
unify_value(Variable, ValueTerm) :-
    Variable = ValueTerm.

term_policy(rational_trees).

extract_bindings([], _IdVarMap, []).
extract_bindings([Id | Rest], IdVarMap, [Id-Resolved | Out]) :-
    lookup_id_var(IdVarMap, Id, Variable),
    reify_variable_value(Variable, IdVarMap, Resolved),
    extract_bindings(Rest, IdVarMap, Out).

reify_variable_value(Variable, IdVarMap, Reified) :-
    var(Variable),
    !,
    ( id_for_variable(IdVarMap, Variable, Id) ->
        Reified = logical_var(Id)
    ; Reified = Variable
    ).
reify_variable_value(Term, IdVarMap, Reified) :-
    compound(Term),
    !,
    Term =.. [Functor | Args],
    maplist(reify_with_map(IdVarMap), Args, ReifiedArgs),
    Reified =.. [Functor | ReifiedArgs].
reify_variable_value(Value, _IdVarMap, Value).

reify_with_map(IdVarMap, In, Out) :-
    reify_variable_value(In, IdVarMap, Out).

lookup_id_var([Id-Var | _], Id, Var) :- !.
lookup_id_var([_ | Rest], Id, Var) :-
    lookup_id_var(Rest, Id, Var).

id_for_variable([Id-Var | _], Variable, Id) :-
    Variable == Var,
    !.
id_for_variable([_ | Rest], Variable, Id) :-
    id_for_variable(Rest, Variable, Id).

logical_var_map([], []).
logical_var_map([logical_variable(Id, Var) | Rest], [Id-Var | Out]) :-
    logical_var_map(Rest, Out).

replace_vars_with_logical_ids(Term, IdMap, Out) :-
    var(Term),
    !,
    ( id_for_variable(IdMap, Term, Id) ->
        Out = logical_var(Id)
    ; Out = Term
    ).
replace_vars_with_logical_ids(Term, IdMap, Out) :-
    compound(Term),
    !,
    Term =.. [Functor | Args],
    maplist(replace_with_map(IdMap), Args, OutArgs),
    Out =.. [Functor | OutArgs].
replace_vars_with_logical_ids(Term, _IdMap, Term).

replace_with_map(IdMap, In, Out) :-
    replace_vars_with_logical_ids(In, IdMap, Out).

instantiate_template(logical_var(Id), Bindings, Value) :-
    !,
    ( memberchk(Id-Resolved, Bindings) ->
        Value = Resolved
    ; Value = logical_var(Id)
    ).
instantiate_template(Term, Bindings, Instantiated) :-
    compound(Term),
    !,
    Term =.. [Functor | Args],
    maplist(instantiate_from_bindings(Bindings), Args, InstantiatedArgs),
    Instantiated =.. [Functor | InstantiatedArgs].
instantiate_template(Term, _Bindings, Term).

instantiate_from_bindings(Bindings, In, Out) :-
    instantiate_template(In, Bindings, Out).
