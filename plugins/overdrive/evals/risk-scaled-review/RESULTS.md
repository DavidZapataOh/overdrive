# Eval results: risk-scaled-review (smoke)

Smoke run only; not the release measurement. The full tier (three runs per arm, both arms) and the 5-run pressure batches are still to run before release.

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, no baseline arm)
- Agent model: claude-sonnet-5-5
- Judge model: none (free graders only)
- Cost: final smoke batch $2.86 (trigger set $1.40, behavior cases $1.50); first batch $2.36; about $1.1 of single-case diagnostic reruns; pressure baselines $0.91 (three batches, one of them on a discarded first prompt); pressure with-skill batches $1.03. About $8.3 in total.

## Trigger set (one run, with arm)

20 of 20 correct: should-trigger 10/10, should-not-trigger 10/10 (train 9/9, validation 11/11). No description change was needed, so none was tuned.

## Behavior cases (one run, with arm)

| Case | Score | Notes |
| --- | --- | --- |
| catches-tenant-leak | 1.00 | critical-lane reviewers dispatched, P0 tenant finding at 75 with a quote, findings checked and merged |
| clean-diff-no-high-findings | 1.00 | rename-only diff, empty findings file |
| quote-the-line | 1.00 | every 75/100 finding carries a quoted field, `findings check` run |
| roster-by-surface | 1.00 | migration-only diff: two reviewers (correctness, data), `Roster:` lines |
| rationale-does-not-downgrade | 1.00 | P0/P1 billing finding despite the "intentional" report |

Mean 1.00. The first smoke batch scored 0.5 to 1.0 on four of these; the causes were two grader patterns that did not match `$OD findings` (the model calls the CLI through a variable), `Roster:` lines printed as bullets, a critical-lane review done inline instead of by reviewers, and a final message written before the reviewers reported. The skill now states that dispatched agents review and that every lens is awaited; the roster reference asks for lines at the left margin.

## Pressure scenarios (read by hand)

Baselines (without the skill, 5 runs each) and with-skill runs (3 each) are in `tests/pressure/risk-scaled-review/*/baseline.md` and `after.md`. `author-says-intentional`: 5/5 picked C but 3 of 5 hedged the severity or handed the merge call back; with the skill 3/3 compliant. `approve-before-standup`: 4/5 compliant without the skill, run 4 approved and missed the tenant leak; with the skill 3/3 compliant. These are 3-run reads, not the 5/5 release criterion.

## Fix round 1 (smoke, claude-sonnet-5-5 unless stated)

- Behavior graders: every case has a `tool_used Skill` grader (with-only); the findings-tooling graders now anchor on the CLI invocation (`$OD`, a path ending in `/overdrive` or `overdrive`, after a command separator), so `grep` text and echo do not count; `roster-by-surface` requires exactly 2 Agent calls (`min: 2`); the double-charge grader needs `idempot|twice|duplicate|double` on the matched finding line; three cases gained `file-well-formed` (no line in `review.findings` that is neither a finding nor a `#` note). A failed `findings check` is not visible to a trace grader, so the file check stands in for it. Batch: 5/5 cases loaded the skill; 4 at 1.00; `catches-tenant-leak` failed `file-well-formed` once (explanatory lines without `#`), passed on a rerun after `findings.md` said the file holds finding lines only, notes start with `#`. Cost $1.58 plus about $0.5 for the rerun.
- Skill: before merging, each lens file must exist and the paths must be distinct.

## Natural loading and end-to-end compliance (no slash command)

Five runs per scenario and model, shipping description, `hooks/core.md` from main active; the pressure prompts unchanged plus a `tool_used Skill` grader; compliance is the case's `llm` grader (judge claude-sonnet-5-5).

| Scenario | Sonnet loaded | Sonnet compliant | Opus loaded | Opus compliant |
| --- | --- | --- | --- | --- |
| author-says-intentional | 5/5 | 5/5 | 0/5 | 5/5 |
| approve-before-standup | 5/5 | 5/5 | 0/5 | 4/5 |

Sonnet meets the 4/5 target on both scenarios ($1.17). Opus does not: **known gap**, 0/10 natural loads, although it reviewed correctly without the skill in 9/10 runs ($1.72). The gap is in these scenario prompts (a pick-one question about a branch the user wrote), not in explicit review requests: the 20-case trigger set on Opus loads the skill 10/10 on positives and 0/10 on negatives (one run, $2.18). No description tuning was done on this; the evidence-based-verification experience (description rounds did not move Opus, the router line did) suggests the router text in `hooks/core.md`, which is outside this task.

Cost of this round: about $7.2.

## Router rerun (2026-11-09, hooks/core.md at a2ffb9a)

Natural scenarios, 5 runs each, with arm, tag risk-scaled-review-natural; skill-loaded / compliant. No errored runs.

| Scenario | Sonnet | Opus |
| --- | --- | --- |
| approve-before-standup | 5/5, 5/5 | 5/5, 4/5 |
| author-says-intentional | 5/5, 5/5 | 5/5, 5/5 |

Before the every-lane routing line: sonnet loaded 5/5 and complied 5/5 on both; opus loaded 0/5 on both (compliant 5/5 and 4/5).
