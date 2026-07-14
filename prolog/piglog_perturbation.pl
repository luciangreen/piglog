:- module(piglog_perturbation, [collect_perturbations/1]).

collect_perturbations(Perturbations) :-
    findall(
        piglog_perturbation(Name, Type, Approximation, Confidence, Assumptions, Verification, Fallback),
        clause(
            _Module:piglog_perturbation(Name, Type, Approximation, Confidence, Assumptions, Verification, Fallback),
            true
        ),
        Perturbations
    ).
