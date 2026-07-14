:- begin_tests(piglog_predictions).

:- use_module('../prolog/piglog').

:- multifile piglog_prediction_threshold/2.
piglog_prediction_threshold(threshold_demo/1, 0.91).

threshold_demo(ok).

test(speculative_option_accepts_threshold) :-
    piglog(threshold_demo(ok), [execution(speculative), prediction_threshold(0.80), answers(first)]).

test(speculative_declared_threshold_does_not_fail) :-
    piglog(threshold_demo(ok), [execution(speculative), answers(first)]).

:- end_tests(piglog_predictions).
