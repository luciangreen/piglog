:- module(piglog_converter, [convert_goal/4, conversion_cache_key/2]).

:- use_module(piglog_partition).
:- use_module(piglog_dependencies).
:- use_module(piglog_purity).
:- use_module(piglog_prediction).
:- use_module(piglog_perturbation).
:- use_module(piglog_codegen).

convert_goal(Goal, Options, Hash, Generated) :-
    build_partitions(Goal, Partitions),
    build_dependency_graph(Partitions, Dependencies),
    maplist(classify_partition, Partitions, Purity),
    collect_predictions(Partitions, Predictions),
    collect_perturbations(Perturbations),
    Version = '0.5.0',
    Model = generated{
        goal: Goal,
        options: Options,
        hash: Hash,
        partitions: Partitions,
        dependencies: Dependencies,
        purity: Purity,
        predictions: Predictions,
        perturbations: Perturbations,
        version: Version
    },
    build_generated_code_terms(Model, Version, Terms),
    Generated = Model.put(code_terms, Terms).

conversion_cache_key(Options, Key) :-
    Key = conversion_key(Options.execution, Options.scheduling, Options.answers, Options.code).
