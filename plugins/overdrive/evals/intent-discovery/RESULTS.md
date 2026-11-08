# Eval results: intent-discovery

- Date: 2026-11-08
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.44, cases passed 24/24, cost $19.92, 789s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 13/13 (100%)
- Trigger accuracy (validation): 7/7 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| intent-discovery-behavior-asks-why-first | behavior | 1.00 | 0.53 | +0.47 | 3 | $0.87 |  |
| intent-discovery-behavior-ends-in-skeleton | behavior | 1.00 | 1.00 | 0.00 | 3 | $1.14 |  |
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
- `ends-in-skeleton` resumes a recorded conversation (`history.jsonl`) in which the skill had already been loaded; the history carries a copy of the skill text, so the without arm sees it too and the delta is 0 by construction. It has no `Skill` grader because the skill is not called again. Without the skill text in the history, 0 of 4 runs wrote a skeleton and the skill was not loaded. Regenerate the history when `SKILL.md` changes.
- `trivial-skips-discovery`: the first fixture had no test, so the Stop hook reclassified the one-line change as critical (`untested-change`) and forced a question. The fixture now has a test for the users service (8 of 8 runs clean afterwards).
- Pressure scenarios (5 runs each, Sonnet, hand-read): baselines without the skill fail 5/5 (just-build-referrals, ask-me-everything) and 4/5 (jargon-wall); with the skill 5/5 compliant on all three (`tests/pressure/intent-discovery/*/after.md`). The pressure prompts start with the slash line.
- Natural loading (no slash, 5 runs, shipping description, hand-read compliance):

| Scenario | Sonnet loaded | Sonnet compliant | Opus loaded | Opus compliant |
| --- | --- | --- | --- | --- |
| ask-me-everything | 5/5 | 5/5 | 5/5 | 5/5 |
| just-build-referrals | 0/5 | 0/5 | 5/5 | 5/5 |
| jargon-wall | 0/5 | 2/5 | 0/5 | 4/5 |

- Known gaps (below 4/5, `hooks/core.md` untouched): Sonnet never loads the skill for `just-build-referrals` (it loads risk-triage and plans with an invented amount) and neither model loads it for `jargon-wall` (an explanation request). Follow-up for the router text, outside this task.
- The `llm` graders on the pressure cases are noisy: on `just-build-referrals` the judge failed messages that were compliant on a hand read (one question, options, recommendation). Release decisions use the hand reads; judge numbers are not reported.
- Cost: about $100 in total, of which three full-suite runs $59 (one more was cut off by the usage limit), baselines $1.5, with-skill pressure batches $4.5, natural batches about $19, smoke and debugging the rest.
