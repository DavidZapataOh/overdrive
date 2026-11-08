# Eval results: parallel-execution (smoke)

Smoke numbers only: one run per case, with-skill arm, no baseline arm. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh parallel-execution --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-08
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5
- Judge model: none for smoke (the pressure compliance grader used claude-sonnet-5-5)
- Cost: about $15 in total (two skill-absent smoke runs $4.9, two with-skill smoke runs $3.8, about $1.2 of single-case reruns that kept traces, pressure baseline and with-skill batches $3.6, natural-loading batches $2.6)

## Harness limit that shapes the behavior cases

`claude plugin eval` refuses worktree isolation: every Agent call with `isolation: "worktree"` returns "worktree isolation is unavailable in this session (plugin evaluation harness)", so no builder ever runs. Consequences, recorded rather than worked around in the skill:

- `uses-worktrees` grades the dispatch calls the model makes (`isolation` and `overdrive:builder` in the call input, 3 of each). Those calls are rejected by the harness, so this is the one place a rejected call is counted; the call's parameters are the behavior under test. The briefs the model wrote for each task (`file_exists` on `task-N.md`) are result-side evidence from successful `overdrive brief` calls.
- `integrates-and-tests` starts from the state after the builders: two branches with one commit each, so the merges, tests and integration branch are real and the graders see accepted calls.
- `refuses-overlap` cannot grade a landed `turbo.json` (a correct run dispatches a builder that the harness refuses), so it checks the overlap run, the shared file named in an assistant text block, at most two Agent calls and no brief for the task that must wait.

## Trigger set (one run, with arm)

Final: 20 of 20 correct, should-trigger 10/10, should-not-trigger 10/10 (train 12/12, validation 8/8). No description change was needed, so none was tuned. Without the skill (the red run): train 5/12, validation 5/8, since only the negatives pass.

## Behavior cases (one run, with arm)

| Case | Without the skill | With the skill |
| --- | --- | --- |
| refuses-overlap | 0.20 | 1.00 |
| uses-worktrees | 0.71 | 1.00 |
| integrates-and-tests | 0.83 | 1.00 |

Without the skill the model never ran `overdrive overlap`, merged on `main` and chained the merges (`integrates-and-tests` fails the integration-branch and test-after-merge graders there). The first with-skill batch scored 1.00 on all three; the final batch scored 0.80 on refuses-overlap because of a landed-file grader that punished a correct run (a builder dispatched and refused by the harness), which was replaced.

Grader checks: the merge graders were run against a real trace and against four synthetic traces (two merges in one call, two merges across calls, merge-test-merge, a merge/test loop); they fail the first two and pass the last two.

## Pressure scenario (read by hand)

`six-tasks-at-once`: baseline without the skill 5/5 compliant (so no rationalization table is written); with the skill 5/5 compliant on sonnet. Details in `tests/pressure/parallel-execution/six-tasks-at-once/`.

## Natural loading and end-to-end compliance (no slash command)

Five runs per model, shipping description, `hooks/core.md` active, judge claude-sonnet-5-5.

| Scenario | Sonnet loaded | Sonnet compliant | Opus loaded | Opus compliant |
| --- | --- | --- | --- | --- |
| six-tasks-at-once | 5/5 | 5/5 | 4/5 | 4/5 |

Both models meet the 4/5 target; no known gap. Earlier batch on opus, before merge order was made strict in the skill: 5/5 loaded, 2/5 compliant.
