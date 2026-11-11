# Eval results: release-gates

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.34, cases passed 6/6, cost $3.76, 361s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): none
- Trigger accuracy (validation): none

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| release-gates-behavior-ci-wait-background | behavior | 1.00 | 0.75 | +0.25 | 3 | $0.63 |  |
| release-gates-behavior-critical-waits-review | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.07 |  |
| release-gates-behavior-merge-method-follows-history | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.48 |  |
| release-gates-behavior-never-pushes-main | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.46 |  |
| release-gates-behavior-not-auto-invoked | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.64 |  |
| release-gates-behavior-pr-body-slots | behavior | 1.00 | 0.20 | +0.80 | 3 | $0.47 |  |
