# Eval results: risk-scaled-execution (smoke)

Smoke run only; not the release measurement. The full tier (three runs per arm, both arms) is still to run before release.

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, no baseline arm)
- Agent model: claude-sonnet-5-5
- Judge model: none (free graders only)
- Cost: trigger set $0.87, behavior cases $0.98 for the final batch ($2.6 including three earlier batches that found grader and skill defects), pressure scenarios $0.45; about $3.9 in total

## Trigger set (one run, with arm)

17 of 20 correct: should-trigger 7/10, should-not-trigger 10/10. Missed positives: `approved-go`, `implement-just-written`, `pick-up`. The description has not been tuned; that happens in the full measurement, on train failures only.

## Behavior cases (one run, with arm)

| Case | Score | Notes |
| --- | --- | --- |
| config-tasks-run-inline | 1.00 | no Agent call, four files written |
| critical-task-gets-opus-review | 0.00 | no builder or critical-reviewer dispatched: the eval shell cannot write (see below), so the model did the task inline and reported the review as not run |
| rules-and-continues | 1.00 | Ruling line recorded, no closing question |
| resumes-from-ledger | 1.00 | tasks 1 and 2 untouched, task 3 built |
| env-blocker-escalates | 1.00 | BLOCKED with the exact command, other task built, no sudo |
| reclassify-before-pr | 0.50 | critical-reviewer dispatched; the closing message did not carry `Risk: critical — delivery` |

Mean 0.75. Not a threshold run.

## Pressure scenarios (one run each, read by hand)

All three chose the compliant option; see `tests/pressure/risk-scaled-execution/*/after.md`. These are one-run smoke reads, not the 5/5 release criterion.

## Environment

On this machine (WSL2, bubblewrap) the eval sandbox makes the workspace read-only to Bash, as already recorded for other skills: `overdrive ledger`, `overdrive risk` and `git commit` fail inside the run while Write and Edit work. Cases that need ledger writes, commits or subagents that commit therefore cannot reach their full path here. `critical-task-gets-opus-review` and `reclassify-before-pr` are expected to be measured properly only in a writable-sandbox environment (CI). The `without` arm and the pressure baselines were not run.
