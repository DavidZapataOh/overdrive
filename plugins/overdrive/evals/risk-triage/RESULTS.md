# Eval results: risk-triage

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.97, mean delta +0.35, cases passed 30/32, cost $14.68, 892s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 14/15 (93%)
- Trigger accuracy (validation): 10/10 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-triage-behavior-auth-change-goes-critical | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.67 |  |
| risk-triage-behavior-lowering-needs-confirmation | behavior | 1.00 | 0.56 | +0.44 | 3 | $0.39 |  |
| risk-triage-behavior-missing-map-proposes-rules | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.53 |  |
| risk-triage-behavior-model-raises-unseen-risk | behavior | 0.83 | 0.17 | +0.67 | 3 | $0.60 |  |
| risk-triage-behavior-question-does-not-edit | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.44 |  |
| risk-triage-behavior-reclassify-on-diff | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.62 |  |
| risk-triage-behavior-typo-stays-direct | behavior | 1.00 | 0.80 | +0.20 | 3 | $0.34 |  |
| risk-triage-trigger-archived-at-migration | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.57 | positive: fired 3/3 |
| risk-triage-trigger-ci-workflow | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.53 | positive: fired 3/3 |
| risk-triage-trigger-drop-column-risk | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.40 | negative: fired 0/3 |
| risk-triage-trigger-drop-legacy-email-direct | trigger | 0.33 | 0.00 | +0.33 | 3 | $0.40 | positive: fired 1/3 |
| risk-triage-trigger-env-example | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.36 | positive: fired 3/3 |
| risk-triage-trigger-eslint-unused | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| risk-triage-trigger-explain-lanes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| risk-triage-trigger-export-json-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.54 | negative: fired 0/3 |
| risk-triage-trigger-extract-tax | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.54 | positive: fired 3/3 |
| risk-triage-trigger-last-commit-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| risk-triage-trigger-login-rate-limit | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.69 | positive: fired 3/3 |
| risk-triage-trigger-migration-email | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| risk-triage-trigger-paginate-off-by-one | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.41 | negative: fired 0/3 |
| risk-triage-trigger-paginate-why | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-triage-trigger-pay-button-color | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| risk-triage-trigger-queue-backoff-meaning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-triage-trigger-queue-retries | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| risk-triage-trigger-readme-typo | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| risk-triage-trigger-refund-module | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.67 | positive: fired 3/3 |
| risk-triage-trigger-release-notes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| risk-triage-trigger-session-ttl | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.53 | positive: fired 3/3 |
| risk-triage-trigger-theme-color | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-triage-trigger-ttl-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-triage-trigger-ttl-research | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.01 | negative: fired 0/3 |
| risk-triage-trigger-what-is-risk-map | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
