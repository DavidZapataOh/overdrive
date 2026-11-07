# Eval results: skill-evaluation

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.43, cases passed 5/5, cost $23.60, 1941s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): none
- Trigger accuracy (validation): none

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| skill-evaluation-behavior-baseline-before-skill | behavior | 1.00 | 0.00 | +1.00 | 3 | $10.11 |  |
| skill-evaluation-behavior-description-not-workflow | behavior | 1.00 | 1.00 | 0.00 | 3 | $3.51 |  |
| skill-evaluation-behavior-near-miss-negatives | behavior | 1.00 | 0.00 | +1.00 | 3 | $5.54 |  |
| skill-evaluation-behavior-not-auto-invoked | behavior | 1.00 | 1.00 | 0.00 | 3 | $3.84 |  |
| skill-evaluation-behavior-refuses-unmeasured-claim | behavior | 1.00 | 0.83 | +0.17 | 3 | $1.44 |  |

Provenance: `baseline-before-skill` and `near-miss-negatives` were rerun on the final SKILL.md and graders (`claude plugin eval --case <name> --tag skill-evaluation-behavior --runs 3 --ablation with-without`) and merged into the full-tier result; the other three cases come from the full-tier run of the same day on the previous revision, whose changes since (pressure case names, Report slots, wording) do not touch what those cases grade.
