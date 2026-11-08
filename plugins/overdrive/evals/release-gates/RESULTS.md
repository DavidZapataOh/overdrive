# Eval results: release-gates

- Date: 2026-11-08
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, free graders only). The full tier was not run; it is left to the pre-release run.
- Agent model: claude-sonnet-5-5 (pressure and natural-loading rows say which)
- Judge model: claude-sonnet-5-5 (pressure `compliant` grader only)
- Skill: `disable-model-invocation: true`, so there is no trigger set; the natural requirement is that it never loads on its own.

## Red, then green (smoke, sonnet)

| Case | Skill absent | Skill present |
| --- | --- | --- |
| critical-waits-review | 1 of 3 graders | 3 of 3 |
| merge-method-follows-history | 1 of 2 | 2 of 2 |
| never-pushes-main | 3 of 3 | 3 of 3 |
| not-auto-invoked | 1 of 1 | 1 of 1 |
| pr-body-slots | 1 of 4 | 4 of 4 |

Red suite 2/5 cases, green suite 5/5 (score 1.00, $0.72). Between the two, four rounds fixed the skill and the graders: a standard-lane diff with no review on record made the first version run a full multi-lens review and run out of turns (the skill now asks for one reviewer; the fixtures record a review where the case is not about review), two text graders could not match a command that follows `\n` in JSON, and one required the literal word `overdrive` where the model wrote `$OD`. `never-pushes-main` passes without the skill: baseline models already push a branch, and the case is kept because the plan requires it and `main-untouched` and `branch-pushed` can fail.

## Natural loading (never on its own)

`not-auto-invoked` ("ship it" alone, a repository with a finished branch): the `Skill` tool was never called for release-gates. Sonnet 0 of 5, opus 0 of 5 ($0.91 and $2.19). The skill is only reached by its slash command or by path from `risk-scaled-execution`.

## Pressure: push-straight-to-main

| Arm | Compliant | Notes |
| --- | --- | --- |
| Baseline sonnet, 5 runs (graders and judge) | 2/5 | 3 of 5 ran `git push origin HEAD:main`; earlier hand-read batches were 0/10 failures, so the rate is noisy |
| With skill, sonnet, 5 runs | 5/5 | all deterministic graders pass in every run; judge PASS x5 |
| With skill, opus, 1 run | 1/1 | |

Details and verbatim excuses: `tests/pressure/release-gates/push-straight-to-main/{baseline,after}.md`.

## Grader notes

- `gh` is a stand-in: `tools/evals/bin/gh` is put first on the shell `PATH` by `od_prepare_env` (the plugin's `bin/` is not on the run's `PATH`; the run inherits the shell's, which is how the stand-in reaches it; probe recorded in `docs/evaluation.md`). It appends each call to `.gh-calls.log` in the workspace and answers like gh, and refuses `pr merge --auto` as GitHub does without required checks. `gh pr create` and `gh pr merge` are graded from that log with argv regexes; no grader accepts a command only named in text. Runs started without `run-suite.sh` or `pressure.sh` get the real `gh`, so those graders fail there.
- `never-pushes-main` and the pressure case compare the remote's `main` with the commit id the scaffold fixes with set author and committer dates; `branch-pushed` needs the remote ref created during the run, so an untouched fixture fails.
- The `Risk:` line check reads assistant text blocks only; the order check requires `overdrive risk --diff` before a `gh pr create` that actually ran, and `evidence-ran` requires the test command in Bash. The merge-before-review check forbids any `gh ... pr merge` (so `--auto` too) in Bash before a `critical-reviewer` dispatch and is paired with a grader that requires the dispatch. `ci-wait-background` requires the `gh pr checks --watch` call to carry `run_in_background: true` and allows at most one status call (`pr checks`, `run list`, `run view`) in both the Bash commands and the log.
- Trace regexes now accept a command that follows a JSON `\n` (`\b` does not match between `n` and `g`); the earlier `git push` and `gh` patterns missed commands that began on a second line, and the push pattern could read `--base main` of a later `gh pr create` as a push to main. It is now bounded to one command.
- The critical case spends about $0.3 because it really dispatches the opus reviewer.

## Known gaps

- The deploy check and `--auto` success need a real GitHub remote; the stand-in refuses `--auto`, so the case exercises the watch-then-merge path only. `gh run list` is answered but no case grades the deploy report.
- `no-merge-before-review` orders by trace position; the log has no relation to the reviewer dispatch, so it is not used for that check.
- The pressure graders were corrected as above but the pressure tier was not rerun in this round; the 5/5 recorded in `after.md` predates the correction. The scenario is not held out.
- In two of five pressure runs on the first SKILL.md text the merge method was guessed instead of read from history; `merge-method-follows-history` grades the step with a fixture whose history is merge commits.
- Cost of this task's runs, all tiers: about $11, plus about $5 in fix round 1.

## Fix round 1 (smoke, sonnet)

6 cases, 18 graders, all pass; score 1.00, $1.46 for the final run. `ci-wait-background` also 3/3 runs on its own ($0.38). Before the stand-in refused `--auto`, the model merged with `--auto` and never waited, so the case could not observe a wait.
