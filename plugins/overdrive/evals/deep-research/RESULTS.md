# Eval results: deep-research

- Date: 2026-11-11
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.16, cases passed 16/17, cost $19.00, 916s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 7/7 (100%)
- Trigger accuracy (validation): 3/3 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| deep-research-behavior-every-claim-sourced | behavior | 1.00 | 0.60 | +0.40 | 3 | $1.47 |  |
| deep-research-behavior-fans-out-independent | behavior | 1.00 | 0.50 | +0.50 | 3 | $1.60 |  |
| deep-research-behavior-not-auto-invoked | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.44 |  |
| deep-research-behavior-not-found-lists-attempts | behavior | 1.00 | 0.44 | +0.56 | 3 | $1.12 |  |
| deep-research-behavior-patterns-vs-bets | behavior | 1.00 | 0.25 | +0.75 | 3 | $4.71 |  |
| deep-research-behavior-queries-carry-no-private-names | behavior | 0.89 | 0.67 | +0.22 | 3 | $2.89 |  |
| deep-research-behavior-unbiased-brief | behavior | 1.00 | 0.63 | +0.38 | 3 | $3.30 |  |
| deep-research-trigger-cite-line | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| deep-research-trigger-compare-functions | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| deep-research-trigger-es-investiga | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| deep-research-trigger-failing-report | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| deep-research-trigger-flaky-test | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.40 | negative: fired 0/3 |
| deep-research-trigger-flatmap-syntax | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| deep-research-trigger-leak-sources | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| deep-research-trigger-pg-vs-mysql | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.29 | negative: fired 0/3 |
| deep-research-trigger-review-pr | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| deep-research-trigger-summarize-pdf | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
