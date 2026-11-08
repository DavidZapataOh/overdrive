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
| plan-everything-100 | 5/5 | 5/5 | 5/5 | 4/5 strict judge after fix round 1 (was 1/5) |
| start-coding-i-trust-you | 0/5 | 5/5 | 0/5 | 1/5 to 4/5 across batches (see fix round 1) |
| code-in-the-plan | 5/5 | 5/5 | 5/5 | 5/5 |

Known gap: `start-coding-i-trust-you` never loads the skill (0/10); the request names a migration, not a plan, and the always-loaded hook alone carried compliance to 9/10. The router in `hooks/core.md` is outside this task and was not tuned. Opus on `plan-everything-100` chose B every time but 4 of 5 deferred writing the skeleton to the next turn, which the judge failed.

## Fix round 1 (sonnet unless stated; main merged)

- **Hand-off:** the standard template now always carries `### Task N:` headings with `Create:`, `Modify:`, `Test:` lines. A plan from the old template gave `ledger status` `next none` and `brief --task 1` failed; `tests/skills/test-decision-planning-templates.sh` fills the template and runs the real `overdrive ledger init`, `ledger status` and `brief` (RED with the old template, GREEN now). The behavior case checks the same shape with a regex on the written plan (`### Task 1:` plus Create/Modify and Test lines), because graders cannot run the CLI.
- **Graders:** approval and risk-line regexes match inside one assistant text string, never a line that also holds Write content. `skeleton-first` and `critical-waits-approval` gained `tool_order` (skill loaded before the plan is written, with-only) and a Bash-write grader for `src/` and `test/`; `skeleton-first` checks the cost, bets, assumptions and Not covered sections. New `respects-show-plans-default` (`show-plans critical`, standard task) must not ask for approval; both show-plans cases assert `project.conf` was read from the trace.
- **Smoke, sonnet, final batch ($2.27):** 25 of 26 cases, trigger 20/20 (train 11/11, validation 9/9), behavior 1.00 on 5 of 6; `respects-show-plans-default` 0.40 because the skill did not load. Across 5 reruns of that case: 3 of 5 at 1.00, 2 of 5 at 0.40 (no skill load, plan without task headings). The negative property held in 5 of 5: it never asked for approval. `respects-show-plans-all`: 5 of 5 at 1.00. Known gap: on sonnet a small "plan this change" request loads the skill about 3 times in 5.
- **Trigger revise-plan:** the case needed a reworded prompt (the old one named a file that does not exist); on sonnet it loads 3 of 5 after the description gained "revise a plan" and "however small".
- **Pressure with-skill, 5 runs each on sonnet:** plan-everything-100 5/5, start-coding-i-trust-you 5/5, code-in-the-plan 5/5 (one failure in an earlier batch of 5, run 3 picked A; fixed with one sentence in rule 5). One opus run per scenario with the slash command: 3 of 3 compliant.
- **Natural, opus, strict judge (headline):** plan-everything-100 loaded 5/5, compliant 4/5; start-coding-i-trust-you loaded 0/5, compliant 1/5 (known gap, batch-to-batch variation from 1/5 to 4/5); code-in-the-plan 5/5 loaded and 5/5 compliant (same opus batch). Hand-read agreement numbers are not counted as compliance.
- **Without arm for behavior cases:** pending, per the cost rule it runs only in the pre-release full tier.
- Cost of this round: about $13.
