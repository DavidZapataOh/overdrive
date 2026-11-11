# Eval results: risk-scaled-execution

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.49, cases passed 25/26, cost $18.97, 1509s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 14/14 (100%)
- Trigger accuracy (validation): 6/6 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-scaled-execution-behavior-config-tasks-run-inline | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.56 |  |
| risk-scaled-execution-behavior-critical-task-gets-opus-review | behavior | 1.00 | 0.00 | +1.00 | 3 | $2.86 |  |
| risk-scaled-execution-behavior-env-blocker-escalates | behavior | 0.87 | 0.80 | +0.07 | 3 | $0.61 |  |
| risk-scaled-execution-behavior-reclassify-before-pr | behavior | 1.00 | 0.00 | +1.00 | 3 | $2.97 |  |
| risk-scaled-execution-behavior-resumes-from-ledger | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.59 |  |
| risk-scaled-execution-behavior-rules-and-continues | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.66 |  |
| risk-scaled-execution-trigger-approved-go | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.65 | positive: fired 3/3 |
| risk-scaled-execution-trigger-continue-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| risk-scaled-execution-trigger-ejecuta-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.76 | positive: fired 3/3 |
| risk-scaled-execution-trigger-execute-plan-file | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.61 | positive: fired 3/3 |
| risk-scaled-execution-trigger-execute-query | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| risk-scaled-execution-trigger-fix-ci | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| risk-scaled-execution-trigger-implement-just-written | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.06 | positive: fired 3/3 |
| risk-scaled-execution-trigger-next-slice | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.63 | positive: fired 3/3 |
| risk-scaled-execution-trigger-pick-up | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.65 | positive: fired 3/3 |
| risk-scaled-execution-trigger-resume-docker | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| risk-scaled-execution-trigger-review-pr | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.51 | negative: fired 0/3 |
| risk-scaled-execution-trigger-run-build | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.39 | negative: fired 0/3 |
| risk-scaled-execution-trigger-run-tests | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-scaled-execution-trigger-slice-two | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.64 | positive: fired 3/3 |
| risk-scaled-execution-trigger-summarize-plan | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| risk-scaled-execution-trigger-tasks-range | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.64 | positive: fired 3/3 |
| risk-scaled-execution-trigger-typo-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| risk-scaled-execution-trigger-whats-left | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-scaled-execution-trigger-write-plan | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.59 | negative: fired 0/3 |
| risk-scaled-execution-trigger-write-plan-es | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.60 | negative: fired 0/3 |
