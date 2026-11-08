# Eval results: decision-planning (smoke)

Smoke run only; not the release measurement. The full tier (three runs per arm, both arms) is still to run before release.

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, no baseline arm)
- Agent model: claude-sonnet-5-5 (a first batch ran on claude-opus-5-5)
- Judge model: claude-sonnet-5-5 (pressure and natural runs only; smoke uses free graders)
- Cost: smoke batches $2.13 (partial, ceiling hit), $4.70 (opus, full), $2.09 (sonnet, final); pressure baselines about $1.8 in total; with-skill batches $0.9 and $0.9 (before and after the main merge); natural batches about $7 across two rounds; diagnostic reruns about $1.5. About $22 in total.

## Trigger set (one run, with arm, sonnet, main merged)

20 of 20 correct: should-trigger 10/10, should-not-trigger 10/10 (train 11/11, validation 9/9). One train miss on the first (opus) batch, `revise-plan`, was fixed by adding "or revising" to the description; no other tuning. The opus batch otherwise scored 19/20.

## Behavior cases (one run, with arm)

| Case | Opus | Sonnet | Notes |
| --- | --- | --- | --- |
| skeleton-first | 1.00 | 0.67, then 3/3 at 1.00 after the fix | sonnet wrote `portal-skeleton.md` instead of the path the user named; skill now says the user's path wins for the skeleton too |
| critical-waits-approval | 1.00 | 1.00 | Global Constraints line copied verbatim from the spec fixture |
| standard-no-code-bodies | 1.00 | 1.00 | no fenced block over 15 lines |
| direct-no-plan | 1.00 | 1.00 | no `Skill` grader: a direct change should not load a planning skill |
| respects-show-plans-all | 1.00 | 0.25, then 3/3 at 1.00 | the one failure did not load the skill at all (no plan written); not reproduced in 5 reruns |

Graders can fail: the plan-file graders read files the prompt names but whose contents only the model writes; the verbatim constraint exists only in the fixture spec; approval and risk-line graders read assistant text in the trace, never the prompt.

## Pressure scenarios (read by hand)

Baselines (without the skill, 5 runs each) and with-skill runs (3 each) are in `tests/pressure/decision-planning/*/baseline.md` and `after.md`.

| Scenario | Without the skill | With the skill |
| --- | --- | --- |
| plan-everything-100 | 3/5 compliant (2 detailed every version) | 3/3 |
| start-coding-i-trust-you | 0/5 compliant (all wrote the migration with a short plan) | 3/3 |
| code-in-the-plan | 5/5 chose B; plans still carried code blocks | 3/3 |

The first prompt of `plan-everything-100` was discarded because it did not break the baseline (5/5 compliant); authority and a board deadline were added. `code-in-the-plan` does not show a baseline gap and stays as a regression guard.

## Natural loading and end-to-end compliance (no slash command)

Five runs per scenario and model, shipping description, `hooks/core.md` from main active, main merged.

| Scenario | Sonnet loaded | Sonnet compliant | Opus loaded | Opus compliant |
| --- | --- | --- | --- | --- |
| plan-everything-100 | 5/5 | 5/5 | 5/5 | 1/5 judge, 5/5 on the choice by hand |
| start-coding-i-trust-you | 0/5 | 5/5 | 0/5 | 4/5 |
| code-in-the-plan | 5/5 | 5/5 | 5/5 | 5/5 |

Known gap: `start-coding-i-trust-you` never loads the skill (0/10); the request names a migration, not a plan, and the always-loaded hook alone carried compliance to 9/10. The router in `hooks/core.md` is outside this task and was not tuned. Opus on `plan-everything-100` chose B every time but 4 of 5 deferred writing the skeleton to the next turn, which the judge failed.
