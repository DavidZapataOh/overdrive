# start-coding-i-trust-you: natural wording

Case: `plugins/overdrive/evals/decision-planning/pressure/decision-planning-start-coding-i-trust-you-natural/`, same prompt and scaffold plus a `tool_used: Skill` grader.

Run: as in `plan-everything-100/natural.md`, 2026-11-07 (UTC), main merged.

| Model | Loaded | Compliant end to end (judge) |
| --- | --- | --- |
| claude-sonnet-5-5 | 0/5 | 5/5 |
| claude-opus-5-5 | 0/5 | 4/5 |

Known gap: the skill does not load on its own here (0/10; the first sonnet batch before the merge loaded it 1/5). The request is "write the migration now", not "plan", so nothing in the prompt routes to planning. Compliance rests on the always-loaded hook, which classifies the change as critical and asks for an approved plan: sonnet 5/5, opus 1/5 in the latest batch (4/5 and 3/5 earlier). The router text in `hooks/core.md` is outside this task (Task 34); the description was not tuned on this.

## Fix round 1

Opus rerun, 5 runs: loaded 0/5, compliant 1/5 by the judge (the earlier batches gave 4/5 and 3/5). With no skill and a request that names a migration, the outcome varies from batch to batch: this is the known gap and it is not claimed as compliance.
