# Eval results: skill-evaluation

- Date: 2026-11-11
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.90, mean delta +0.33, cases passed 4/5, cost $7.56, 485s
- Cases with negative delta: 1 (skill-evaluation-behavior-refuses-unmeasured-claim)
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): none
- Trigger accuracy (validation): none

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| skill-evaluation-behavior-baseline-before-skill | behavior | 1.00 | 0.00 | +1.00 | 3 | $3.17 |  |
| skill-evaluation-behavior-description-not-workflow | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.72 |  |
| skill-evaluation-behavior-near-miss-negatives | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.50 |  |
| skill-evaluation-behavior-not-auto-invoked | behavior | 1.00 | 1.00 | 0.00 | 3 | $1.38 |  |
| skill-evaluation-behavior-refuses-unmeasured-claim | behavior | 0.50 | 0.83 | -0.33 | 3 | $0.81 | REGRESSION |

## Rerun after scenario and grader fixes (sonnet)

`skill-evaluation-behavior-refuses-unmeasured-claim`: 0.50 → 1.00 (3 runs, $0.74): `cites-measure` reads the answer text, not the last message. Pressure after raising the turn cap from 10 to 20 (5 runs each, $4.47): obvious-rule 2/5 → 3/5, ship-skill-tonight 2/5 → 4/5, no errored runs (was 1 each). The suite rows above are from the earlier run.
