# Eval results: intent-discovery

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.44, cases passed 23/24, cost $9.40, 717s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 13/13 (100%)
- Trigger accuracy (validation): 7/7 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| intent-discovery-behavior-asks-why-first | behavior | 0.89 | 0.50 | +0.39 | 3 | $0.45 |  |
| intent-discovery-behavior-ends-in-skeleton | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.57 |  |
| intent-discovery-behavior-no-discoverable-questions | behavior | 0.96 | 0.79 | +0.17 | 3 | $0.46 |  |
| intent-discovery-behavior-trivial-skips-discovery | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.45 |  |
| intent-discovery-trigger-admin-dashboard | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| intent-discovery-trigger-blog-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| intent-discovery-trigger-console-warning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| intent-discovery-trigger-cuotas-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| intent-discovery-trigger-explain-dashboard | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| intent-discovery-trigger-export-data | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| intent-discovery-trigger-fix-referral-bug | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| intent-discovery-trigger-flag-vs-config | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| intent-discovery-trigger-marketplace-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| intent-discovery-trigger-notifications-vague | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| intent-discovery-trigger-plan-next-slice | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| intent-discovery-trigger-puntos-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| intent-discovery-trigger-referidos-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| intent-discovery-trigger-rename-column | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| intent-discovery-trigger-review-wishlist | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| intent-discovery-trigger-team-accounts | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.37 | positive: fired 3/3 |
| intent-discovery-trigger-test-formatter | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| intent-discovery-trigger-typo-title | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| intent-discovery-trigger-variable-names | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.30 | negative: fired 0/3 |
| intent-discovery-trigger-wishlist-en | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
