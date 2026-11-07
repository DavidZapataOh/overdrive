# Eval results: risk-triage

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.56, cases passed 27/27, cost $24.37, 662s
- Provenance: `run-suite.sh risk-triage --tier full --model main`; two trigger cases hit the 8-turn cap in 3 runs, so trigger cases now allow 15 turns and those two cases were rerun (3 runs per arm, $2.05, merged into this result with jq and summarized again with `summarize.sh`).
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 13/13 (100%)
- Trigger accuracy (validation): 7/7 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-triage-behavior-auth-change-goes-critical | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.99 |  |
| risk-triage-behavior-lowering-needs-confirmation | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.70 |  |
| risk-triage-behavior-missing-map-proposes-rules | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.07 |  |
| risk-triage-behavior-model-raises-unseen-risk | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.13 |  |
| risk-triage-behavior-question-does-not-edit | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.76 |  |
| risk-triage-behavior-reclassify-on-diff | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.86 |  |
| risk-triage-behavior-typo-stays-direct | behavior | 1.00 | 0.67 | +0.33 | 3 | $0.83 |  |
| risk-triage-trigger-archived-at-migration | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.79 | positive: fired 3/3 |
| risk-triage-trigger-drop-column-risk | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.75 | negative: fired 0/3 |
| risk-triage-trigger-eslint-unused | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.74 | positive: fired 3/3 |
| risk-triage-trigger-explain-lanes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.71 | negative: fired 0/3 |
| risk-triage-trigger-export-json-flag | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.99 | positive: fired 3/3 |
| risk-triage-trigger-extract-tax | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.94 | positive: fired 3/3 |
| risk-triage-trigger-last-commit-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.69 | negative: fired 0/3 |
| risk-triage-trigger-login-rate-limit | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.09 | positive: fired 3/3 |
| risk-triage-trigger-migration-email | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.49 | negative: fired 0/3 |
| risk-triage-trigger-paginate-off-by-one | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.05 | positive: fired 3/3 |
| risk-triage-trigger-paginate-why | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.64 | negative: fired 0/3 |
| risk-triage-trigger-pay-button-color | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.81 | positive: fired 3/3 |
| risk-triage-trigger-queue-backoff-meaning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.66 | negative: fired 0/3 |
| risk-triage-trigger-queue-retries | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.72 | positive: fired 3/3 |
| risk-triage-trigger-readme-typo | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.70 | positive: fired 3/3 |
| risk-triage-trigger-release-notes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.55 | negative: fired 0/3 |
| risk-triage-trigger-session-ttl | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.74 | positive: fired 3/3 |
| risk-triage-trigger-ttl-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.67 | negative: fired 0/3 |
| risk-triage-trigger-ttl-research | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.60 | negative: fired 0/3 |
| risk-triage-trigger-what-is-risk-map | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.82 | negative: fired 0/3 |
