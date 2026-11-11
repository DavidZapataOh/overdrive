# Eval results: compound-learning

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.50, cases passed 24/25, cost $11.91, 898s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 15/15 (100%)
- Trigger accuracy (validation): 5/5 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| compound-learning-behavior-bar-fails-writes-nothing | behavior | 1.00 | 0.80 | +0.20 | 3 | $0.50 |  |
| compound-learning-behavior-correction-becomes-check | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.55 |  |
| compound-learning-behavior-escaped-defect-calibrates-map | behavior | 0.89 | 0.00 | +0.89 | 3 | $0.57 |  |
| compound-learning-behavior-no-empty-promise | behavior | 0.92 | 0.50 | +0.42 | 3 | $0.61 |  |
| compound-learning-behavior-scope-as-stated | behavior | 1.00 | 0.67 | +0.33 | 3 | $0.64 |  |
| compound-learning-trigger-changelog | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.39 | negative: fired 0/3 |
| compound-learning-trigger-cobro-doble | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
| compound-learning-trigger-console-log-again | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
| compound-learning-trigger-env-example | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| compound-learning-trigger-escaped-ci | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.50 | positive: fired 3/3 |
| compound-learning-trigger-explain-no-console | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| compound-learning-trigger-fechas-bogota | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.58 | positive: fired 3/3 |
| compound-learning-trigger-fix-failing-test | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| compound-learning-trigger-got-past-review | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.66 | positive: fired 3/3 |
| compound-learning-trigger-idioma-otra-vez | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| compound-learning-trigger-last-sprint | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| compound-learning-trigger-learn-codebase | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| compound-learning-trigger-no-mocks | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
| compound-learning-trigger-pnpm-twice | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.45 | positive: fired 3/3 |
| compound-learning-trigger-postmortem-doc | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.50 | negative: fired 0/3 |
| compound-learning-trigger-review-pr | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.45 | negative: fired 0/3 |
| compound-learning-trigger-round-half-up | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.63 | positive: fired 3/3 |
| compound-learning-trigger-teach-hooks | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.41 | negative: fired 0/3 |
| compound-learning-trigger-translate-comments | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| compound-learning-trigger-try-catch | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
