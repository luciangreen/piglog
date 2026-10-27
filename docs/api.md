# API reference

All predicates are provided by `prolog/piglog.pl`.

## `piglog(Goal)`

Converts and runs `Goal` with the defaults described in the [user manual](user_manual.md). The runtime currently calls the original goal directly.

## `piglog(Goal, Options)`

Validates options, converts `Goal` to a generated metadata dict, applies requested code output, checks an execution gate on the entry predicate, and runs the original goal under the selected answer policy.

## `piglog_file(File, Goal, Options)`

Loads `File`, then converts and runs `Goal`. The file path is included in the conversion options and is used when choosing a default generated-code filename.

## `piglog_convert(Goal, Options, Generated)`

Validates and converts a callable goal without running it. `Generated` is a dict containing `goal`, `options`, `hash`, `partitions`, `dependencies`, `logical_variables`, `partition_variables`, `purity`, `predictions`, `perturbations`, `version`, and `code_terms`. `code(return(Code))` also unifies `Code` with the generated term list.

The partition and dependency data are preliminary metadata. Stable variable IDs and `piglog_partition_result/12` records are not yet used to merge results or execute partitions independently. The internal record constructor is `piglog_reassembly:make_partition_result/13`; it validates result status values.

## `piglog_run_generated(Generated, Options)`

Runs the original `Generated.goal` using the provided runtime options after checking the entry goal's gate. It does not interpret saved generated source terms.

## `piglog_show_code(Generated)`

Prints the generated code terms using `portray_clause/1`.

## `piglog_save_code(Generated, File)`

Writes the generated code terms to `File`. These terms are for inspection and are not an executable replacement for the source goal.

## `piglog_clear_cache/0`

Clears the in-memory conversion cache.

## `piglog_clear_profile/0`

Clears the reserved in-memory profile cache. Profiling is not currently collected.

## `piglog_unlock(Gate)` and `piglog_lock(Gate)`

Set the in-memory state of `Gate` for the current SWI-Prolog session. Only a matching gate on the entry predicate is enforced today.

See the [user manual](user_manual.md) for accepted options and limitations, and [feature status](feature_status.md) for implementation progress.
