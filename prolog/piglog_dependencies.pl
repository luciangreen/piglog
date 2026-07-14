:- module(piglog_dependencies, [build_dependency_graph/2]).

build_dependency_graph(Partitions, Dependencies) :-
    findall(
        piglog_dependency(FromId, ToId, requires_bound(Shared)),
        dependency_edge(Partitions, FromId, ToId, Shared),
        Dependencies
    ).

dependency_edge(Partitions, FromId, ToId, Shared) :-
    nth1(I, Partitions, partition(FromId, _FromGoal, _FromReq, FromProduces, _)),
    nth1(J, Partitions, partition(ToId, _ToGoal, ToRequires, _ToProd, _)),
    J > I,
    member(Shared, FromProduces),
    memberchk(Shared, ToRequires).
