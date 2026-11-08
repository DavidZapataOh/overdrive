# Eval results: intent-discovery

- Date: 2026-11-08
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite (full tier, before the grader changes of fix round 1): score 1.00, mean delta +0.44 over 24 cases, +0.46 over the 23 cases that measure the skill (`ends-in-skeleton` excluded, see below), cases passed 24/24, cost $19.92, 789s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 13/13 (100%)
- Trigger accuracy (validation): 7/7 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| intent-discovery-behavior-asks-why-first | behavior | 1.00 | 0.53 | +0.47 | 3 | $0.87 |  |
| intent-discovery-behavior-ends-in-skeleton | behavior | 1.00 | 1.00 | 0.00 | 3 | $1.14 | regression guard, not a skill-effect case; excluded from the mean delta |
| intent-discovery-behavior-no-discoverable-questions | behavior | 1.00 | 0.80 | +0.20 | 3 | $0.90 |  |
| intent-discovery-behavior-trivial-skips-discovery | behavior | 1.00 | 1.00 | 0.00 | 3 | $1.14 |  |
| intent-discovery-trigger-admin-dashboard | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.79 | positive: fired 3/3 |
| intent-discovery-trigger-blog-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.82 | positive: fired 3/3 |
| intent-discovery-trigger-console-warning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.71 | negative: fired 0/3 |
| intent-discovery-trigger-cuotas-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.82 | positive: fired 3/3 |
| intent-discovery-trigger-explain-dashboard | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.72 | negative: fired 0/3 |
| intent-discovery-trigger-export-data | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.80 | positive: fired 3/3 |
| intent-discovery-trigger-fix-referral-bug | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.76 | negative: fired 0/3 |
| intent-discovery-trigger-flag-vs-config | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.74 | negative: fired 0/3 |
| intent-discovery-trigger-marketplace-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.83 | positive: fired 3/3 |
| intent-discovery-trigger-notifications-vague | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.86 | positive: fired 3/3 |
| intent-discovery-trigger-plan-next-slice | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.86 | negative: fired 0/3 |
| intent-discovery-trigger-puntos-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.86 | positive: fired 3/3 |
| intent-discovery-trigger-referidos-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.79 | positive: fired 3/3 |
| intent-discovery-trigger-rename-column | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.79 | negative: fired 0/3 |
| intent-discovery-trigger-review-wishlist | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.08 | negative: fired 0/3 |
| intent-discovery-trigger-team-accounts | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.78 | positive: fired 3/3 |
| intent-discovery-trigger-test-formatter | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.76 | negative: fired 0/3 |
| intent-discovery-trigger-typo-title | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.73 | negative: fired 0/3 |
| intent-discovery-trigger-variable-names | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.58 | negative: fired 0/3 |
| intent-discovery-trigger-wishlist-en | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.81 | positive: fired 3/3 |

## Notes

- Model for the suite: `--model main` (claude-opus-5-5); the skill is not followed by a builder agent, so no sonnet suite. Final suite run after merging main.
- Red before the skill: the smoke tier with the skill absent scored 0.69 (trigger 10/13 train, 5/7 validation; behavior 0.00 to 0.83). The trigger positives "fired" only because the router in `hooks/core.md` names the skill and the `tool_used` grader counts a Skill call even when the skill does not exist; the behavior cases (skeleton, one question, recommendation, trivial) failed as intended.
- `ends-in-skeleton` is a regression guard, not a skill-effect case. It resumes a recorded conversation (`history.jsonl`) in which the skill had already been loaded; the history carries a copy of the skill text, so the without arm sees it too and the delta is 0 by construction. It has no `Skill` grader because the skill is not called again, and it is left out of every mean delta quoted here. Without the skill text in the history, 0 of 4 runs wrote a skeleton and the skill was not loaded. Regenerate the history when `SKILL.md` changes. Since fix round 1 the prompt no longer names a file, so `file_exists` checks the skill's default path (`.overdrive/run/skeleton-*.md`), the content checks read the Write call in the trace, and the hand-off line is read from the assistant text blocks because the Stop hook can replace the final message with a risk line.
- `trivial-skips-discovery`: the first fixture had no test, so the Stop hook reclassified the one-line change as critical (`untested-change`) and forced a question. The fixture now has a test for the users service (8 of 8 runs clean afterwards).
- Pressure and natural results are in the next section (fix round 1). The numbers that stood here before it (hand reads of the first batches) were replaced by it.
- Known gaps (natural load below 4/5, `hooks/core.md` untouched): Sonnet never loads the skill for `just-build-referrals` (it loads risk-triage and plans with an invented amount) and neither model loads it for `jargon-wall` (an explanation request). Follow-up for the router text, outside this task.
- Cost of the original task: about $100 in total, of which three full-suite runs $59 (one more was cut off by the usage limit), baselines $1.5, with-skill pressure batches $4.5, natural batches about $19, smoke and debugging the rest.

## Fix round 1: pressure and natural graders, judge reliability

Date 2026-11-08, Claude Code 2.1.319, pinned IDs from `tools/evals/models.env`, judge claude-sonnet-5-5. Smoke only: no full suite was run, so the delta table above predates the grader changes.

Smoke after the changes (opus, with the skill, free graders): asks-why-first 1/1, no-discoverable-questions 1/1, ends-in-skeleton 3/3, all score 1.00.

Graders added. The three behavior cases check the facts-before-first-question order in the trace (`Read`, `Grep` or `Bash` before the first assistant text that asks), and `no-discoverable-questions` accepts a `Read` or `cat` of `.overdrive/decisions.md` as well as `overdrive recall`. They pin one question as one line ending in a question mark and a recommendation line. `asks-why-first` pins the why to the question line inside assistant text blocks. Every pressure and natural case gets free positive graders besides the `llm` judge: one question, a recommendation line, no developer jargon (or, for the stack scenario, no stack question), no announced follow-up question, and no file written by `Bash`. They are strict about the skill's own shape (the question is the last thing on its line) and miss announcements phrased in other words.

Hand read = one question, no announced follow-up, shape of `references/questions.md`, plain language, nothing built or written. Pass counts, 5 runs each. "Loaded" is the Skill-tool call (natural arms only). Final reference text applies to the rows marked final; earlier attempts are listed after the table.

| Scenario | Arm | Model | Loaded | Hand read | Judge | Free positives |
| --- | --- | --- | --- | --- | --- | --- |
| just-build-referrals | without skill, slash prompt | sonnet | n/a | 0/5 | 0/5 | 0/5 (3 of 5 wrote files) |
| just-build-referrals | with skill, slash (final) | sonnet | n/a | 5/5 | 5/5 | 5/5 |
| ask-me-everything | without skill, slash prompt | sonnet | n/a | 0/5 | 0/5 | 0/5 |
| ask-me-everything | with skill, slash (final) | sonnet | n/a | 5/5 | 5/5 | 5/5 |
| jargon-wall | without skill, slash prompt | sonnet | n/a | 5/5 | 4/5 | 5/5 |
| jargon-wall | with skill, slash (final) | sonnet | n/a | 5/5 | 3/5 | 5/5 |
| just-build-referrals | natural | sonnet | 0/5 | 0/5 | 0/5 | 0/5 |
| just-build-referrals | natural | opus | 4/5 | 5/5 | 4/5 | 5/5 |
| ask-me-everything | natural | sonnet | 4/5 | 4/5 | 4/5 | 4/5 |
| ask-me-everything | natural | opus | 5/5 | 5/5 | 5/5 | 5/5 |
| jargon-wall | natural | sonnet | 0/5 | 1/5 | 4/5 | 4/5 |
| jargon-wall | natural | opus | 0/5 | 0/5 | 0/5 | 2/5 |

- `jargon-wall` does not separate the arms: without the skill, Sonnet explains the terms, asks one question and recommends in 5 of 5 runs this round (the first baselines read 4 of 5 failing for asking what the repo answers, which this rubric does not test). It guards plain language with the skill loaded, not the skill's effect.
- Natural arms are unchanged in kind from the first round: Sonnet never loads the skill for `just-build-referrals` (it plans with an invented $10.000, two runs also wrote files) or for `jargon-wall`; Opus loads it for `just-build-referrals` and `ask-me-everything`. On `jargon-wall` every unaided run, both models, ends by announcing the next question or asking a second one, so the strict hand read is lower than the first round's (2/5 and 4/5), which tolerated that.
- Earlier attempts this round, same scenarios with the skill, slash prompt. Before the reference changes: just-build-referrals hand 5/5 (judge 5/5, free 4/5), ask-me-everything hand 3/5 (two questions joined by "and", judge 3/5), jargon-wall hand 3/5 (the repo's stack named unexplained, judge 1/5). After the first reference change (found line in the user's terms, one ask per question): jargon-wall hand 3/5 (a rhetorical framing question plus the real one in two runs, judge 3/5). The final row follows the sentence about framing questions. just-build-referrals and ask-me-everything were not rerun after that last sentence.

### The judge, quantified

Across 80 hand-read runs (35 with-skill slash, 15 without-skill slash, 30 natural; 49 hand-pass, 31 hand-fail):

| Grader | Fails a run the hand read passes | Passes a run the hand read fails |
| --- | --- | --- |
| `llm` judge (Sonnet, 2 of 3 votes) | 9 of 49 (18%) | 6 of 31 (19%) |
| free positive graders | 2 of 49 (4%) | 7 of 31 (23%) |

The judge is unreliable on these rubrics in both directions: on `jargon-wall` with the skill it agreed with the hand read on 3 of 5 runs in the final batch and on only 1 of 5 in the second attempt. Its failures were not tied to one rubric clause (it failed compliant `just-build-referrals` and `jargon-wall` messages that had one question, options and a recommendation). Release decisions use the hand reads and the free graders together; the free graders almost never fail a compliant run but miss compound questions and announced follow-ups, which the hand read catches.
