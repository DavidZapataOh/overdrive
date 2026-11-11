# Eval results: evidence-based-verification

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.98, mean delta +0.46, cases passed 22/24, cost $9.63, 846s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 10/10 (100%)
- Trigger accuracy (validation): 10/10 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| evidence-based-verification-behavior-claims-require-fresh-run | behavior | 0.89 | 0.67 | +0.22 | 3 | $0.42 |  |
| evidence-based-verification-behavior-close-has-three-slots | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.44 |  |
| evidence-based-verification-behavior-not-found-lists-attempts | behavior | 0.67 | 0.50 | +0.17 | 3 | $0.46 |  |
| evidence-based-verification-behavior-phantom-completion | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.42 |  |
| evidence-based-verification-trigger-ci-workflow | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.56 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-file-handle | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-this-out | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| evidence-based-verification-trigger-confirm-deploy | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| evidence-based-verification-trigger-definition-of-done | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| evidence-based-verification-trigger-deploy-script | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.52 | negative: fired 0/3 |
| evidence-based-verification-trigger-end-of-day | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| evidence-based-verification-trigger-explain-verification | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| evidence-based-verification-trigger-fixed-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| evidence-based-verification-trigger-is-it-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| evidence-based-verification-trigger-listo-avisar | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| evidence-based-verification-trigger-ready-to-merge | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| evidence-based-verification-trigger-rename-done-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| evidence-based-verification-trigger-subagent-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| evidence-based-verification-trigger-traducir-mensaje | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.28 | negative: fired 0/3 |
| evidence-based-verification-trigger-vendor-price | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| evidence-based-verification-trigger-verify-email-regex | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| evidence-based-verification-trigger-why-test-failing | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| evidence-based-verification-trigger-write-tests | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| evidence-based-verification-trigger-ya-quedo-verifica | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
