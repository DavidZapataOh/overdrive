# Eval results: test-driven-development

- Date: 2026-11-11
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.93, mean delta +0.41, cases passed 21/24, cost $12.25, 943s
- Cases with negative delta: none
- Cases with errored runs: 1 (test-driven-development-trigger-regression)

## Trigger accuracy

- Trigger accuracy (train): 12/14 (86%)
- Trigger accuracy (validation): 6/6 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| test-driven-development-behavior-config-change-is-tdd-na | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.38 |  |
| test-driven-development-behavior-critical-has-non-regression | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.79 |  |
| test-driven-development-behavior-pinned-test-not-edited-in-green | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.45 |  |
| test-driven-development-behavior-test-before-code | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.73 |  |
| test-driven-development-trigger-add-slugify | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
| test-driven-development-trigger-behavior-change | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.54 | positive: fired 3/3 |
| test-driven-development-trigger-coverage | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| test-driven-development-trigger-debug-ci | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.43 | negative: fired 0/3 |
| test-driven-development-trigger-explain-tdd | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| test-driven-development-trigger-flaky | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.39 | negative: fired 0/3 |
| test-driven-development-trigger-new-endpoint | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.61 | positive: fired 3/3 |
| test-driven-development-trigger-off-by-one | trigger | 0.67 | 0.00 | +0.67 | 3 | $0.63 | positive: fired 2/3 |
| test-driven-development-trigger-one-line-fix | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.61 | positive: fired 3/3 |
| test-driven-development-trigger-refund-rule | trigger | 0.00 | 0.00 | 0.00 | 3 | $0.64 | positive: fired 0/3 |
| test-driven-development-trigger-regression | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.76 | positive: fired 2/2, 2/3 runs graded |
| test-driven-development-trigger-rename-var | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| test-driven-development-trigger-review-tests | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| test-driven-development-trigger-run-suite | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| test-driven-development-trigger-setup-vitest | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.46 | negative: fired 0/3 |
| test-driven-development-trigger-spanish-explain | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| test-driven-development-trigger-spanish-feature | trigger | 0.67 | 0.00 | +0.67 | 3 | $0.67 | positive: fired 2/3 |
| test-driven-development-trigger-typo-bug | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.54 | positive: fired 3/3 |
| test-driven-development-trigger-update-readme | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.39 | negative: fired 0/3 |
| test-driven-development-trigger-validate-email | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.63 | positive: fired 3/3 |
