:- module(
    piglog_prediction,
    [collect_predictions/2, prediction_threshold_for/3]
).

collect_predictions(Partitions, Predictions) :-
    findall(
        piglog_prediction(PartitionId, Value, Confidence, Source, Assumptions, Verification),
        predicted_partition(Partitions, PartitionId, Value, Confidence, Source, Assumptions, Verification),
        Predictions
    ).

predicted_partition(Partitions, PartitionId, Value, Confidence, source(hint), Assumptions, Verification) :-
    member(partition(PartitionId, Goal, _Req, _Prod, _), Partitions),
    functor(Goal, Name, Arity),
    Hint = Name/Arity,
    clause(
        _Module:piglog_prediction(Hint, Value, Confidence, source(hint), Assumptions, Verification),
        true
    ).

prediction_threshold_for(Goal, Options, Threshold) :-
    strip_module(Goal, _, PlainGoal),
    functor(PlainGoal, Name, Arity),
    Pred = Name/Arity,
    ( clause(_Module:piglog_prediction_threshold(Pred, Value), true) ->
        Threshold = Value
    ; get_dict(prediction_threshold, Options, pred(Pred, Value)) ->
        Threshold = Value
    ; get_dict(prediction_threshold, Options, Value),
      number(Value) ->
        Threshold = Value
    ; Threshold = 0.90
    ).
