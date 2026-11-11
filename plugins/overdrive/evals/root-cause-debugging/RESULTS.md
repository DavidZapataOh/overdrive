# Eval results: root-cause-debugging

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.51, cases passed 23/24, cost $10.75, 765s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 15/15 (100%)
- Trigger accuracy (validation): 5/5 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| root-cause-debugging-behavior-debug-logs-removed | behavior | 0.89 | 0.44 | +0.44 | 3 | $0.58 |  |
| root-cause-debugging-behavior-regression-test-added | behavior | 1.00 | 0.17 | +0.83 | 3 | $0.49 |  |
| root-cause-debugging-behavior-repro-before-fix | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.50 |  |
| root-cause-debugging-behavior-root-not-symptom | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.48 |  |
| root-cause-debugging-trigger-add-logging | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.61 | negative: fired 0/3 |
| root-cause-debugging-trigger-checkout-500 | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| root-cause-debugging-trigger-debug-mode-config | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| root-cause-debugging-trigger-explain-econnreset | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| root-cause-debugging-trigger-explain-stack-trace | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| root-cause-debugging-trigger-flaky | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| root-cause-debugging-trigger-health-endpoint | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.61 | negative: fired 0/3 |
| root-cause-debugging-trigger-last-page | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.47 | positive: fired 3/3 |
| root-cause-debugging-trigger-launch-config | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.40 | negative: fired 0/3 |
| root-cause-debugging-trigger-loops-forever | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| root-cause-debugging-trigger-off-by-one-cent | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.51 | positive: fired 3/3 |
| root-cause-debugging-trigger-prod-only | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| root-cause-debugging-trigger-readme | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| root-cause-debugging-trigger-regression | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.44 | positive: fired 3/3 |
| root-cause-debugging-trigger-rename-var | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| root-cause-debugging-trigger-spanish-explain | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| root-cause-debugging-trigger-spanish-login | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.53 | positive: fired 3/3 |
| root-cause-debugging-trigger-spanish-total | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.49 | positive: fired 3/3 |
| root-cause-debugging-trigger-tests-new-feature | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.49 | negative: fired 0/3 |
| root-cause-debugging-trigger-type-error | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.44 | positive: fired 3/3 |
