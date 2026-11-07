# Eval results: risk-triage

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.92, mean delta +0.31, cases passed 27/31, cost $24.66, 666s
- Provenance: `run-suite.sh risk-triage --tier full --model main`, every case rerun after the router change (the router text reaches every case). Turn limits: trigger cases 15, behavior cases 40. Trigger cases grant `Read, Glob, Grep, Skill, Bash, Edit, Write`. Three cases do not meet the bar here (see the fix-round notes): `pay-button-color` (negative, fired 3/3), `drop-legacy-email-direct` (positive, fired 0/3), `missing-map-proposes-rules` (no proposal); a follow-up investigation was cut short by the account's usage limit.
- Cases with negative delta: 1 (risk-triage-trigger-pay-button-color)
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 14/15 (93%)
- Trigger accuracy (validation): 8/9 (89%), floor 90%: FAIL

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-triage-behavior-auth-change-goes-critical | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.01 |  |
| risk-triage-behavior-lowering-needs-confirmation | behavior | 0.89 | 0.33 | +0.56 | 3 | $0.82 |  |
| risk-triage-behavior-missing-map-proposes-rules | behavior | 0.50 | 0.50 | 0.00 | 3 | $0.65 |  |
| risk-triage-behavior-model-raises-unseen-risk | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.21 |  |
| risk-triage-behavior-question-does-not-edit | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.76 |  |
| risk-triage-behavior-reclassify-on-diff | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.91 |  |
| risk-triage-behavior-typo-stays-direct | behavior | 1.00 | 0.80 | +0.20 | 3 | $0.63 |  |
| risk-triage-trigger-archived-at-migration | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.86 | positive: fired 3/3 |
| risk-triage-trigger-ci-workflow | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.89 | positive: fired 3/3 |
| risk-triage-trigger-drop-column-risk | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.74 | negative: fired 0/3 |
| risk-triage-trigger-drop-legacy-email-direct | trigger | 0.00 | 0.00 | 0.00 | 3 | $0.68 | positive: fired 0/3 |
| risk-triage-trigger-env-example | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.72 | positive: fired 3/3 |
| risk-triage-trigger-eslint-unused | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.69 | negative: fired 0/3 |
| risk-triage-trigger-explain-lanes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.70 | negative: fired 0/3 |
| risk-triage-trigger-export-json-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.93 | negative: fired 0/3 |
| risk-triage-trigger-extract-tax | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.87 | positive: fired 3/3 |
| risk-triage-trigger-last-commit-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.69 | negative: fired 0/3 |
| risk-triage-trigger-login-rate-limit | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.94 | positive: fired 3/3 |
| risk-triage-trigger-migration-email | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.49 | negative: fired 0/3 |
| risk-triage-trigger-paginate-off-by-one | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.80 | negative: fired 0/3 |
| risk-triage-trigger-paginate-why | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.62 | negative: fired 0/3 |
| risk-triage-trigger-pay-button-color | trigger | 0.00 | 1.00 | -1.00 | 3 | $0.94 | negative: fired 3/3; REGRESSION |
| risk-triage-trigger-queue-backoff-meaning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.67 | negative: fired 0/3 |
| risk-triage-trigger-queue-retries | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.66 | negative: fired 0/3 |
| risk-triage-trigger-readme-typo | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.63 | negative: fired 0/3 |
| risk-triage-trigger-refund-module | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.03 | positive: fired 3/3 |
| risk-triage-trigger-release-notes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.55 | negative: fired 0/3 |
| risk-triage-trigger-session-ttl | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.80 | positive: fired 3/3 |
| risk-triage-trigger-ttl-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.66 | negative: fired 0/3 |
| risk-triage-trigger-ttl-research | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.35 | negative: fired 0/3 |
| risk-triage-trigger-what-is-risk-map | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.90 | negative: fired 0/3 |
