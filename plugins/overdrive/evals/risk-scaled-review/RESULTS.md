# Eval results: risk-scaled-review

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.98, mean delta +0.51, cases passed 24/25, cost $13.53, 934s
- Cases with negative delta: 1 (risk-scaled-review-behavior-clean-diff-no-high-findings)
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 9/9 (100%)
- Trigger accuracy (validation): 11/11 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-scaled-review-behavior-catches-tenant-leak | behavior | 0.92 | 0.00 | +0.92 | 3 | $1.65 |  |
| risk-scaled-review-behavior-clean-diff-no-high-findings | behavior | 0.50 | 1.00 | -0.50 | 3 | $1.06 | REGRESSION |
| risk-scaled-review-behavior-quote-the-line | behavior | 1.00 | 0.25 | +0.75 | 3 | $0.46 |  |
| risk-scaled-review-behavior-rationale-does-not-downgrade | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.37 |  |
| risk-scaled-review-behavior-roster-by-surface | behavior | 1.00 | 0.33 | +0.67 | 3 | $1.34 |  |
| risk-scaled-review-trigger-address-comments | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| risk-scaled-review-trigger-agent-slice | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| risk-scaled-review-trigger-cambios-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| risk-scaled-review-trigger-check-diff-bugs | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.38 | positive: fired 3/3 |
| risk-scaled-review-trigger-checklist-template | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| risk-scaled-review-trigger-commit-range | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.36 | positive: fired 3/3 |
| risk-scaled-review-trigger-diff-stat | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| risk-scaled-review-trigger-explain-diff | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| risk-scaled-review-trigger-fix-ci-test | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.40 | negative: fired 0/3 |
| risk-scaled-review-trigger-merge-reviewed | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.41 | negative: fired 0/3 |
| risk-scaled-review-trigger-ortografia-es | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| risk-scaled-review-trigger-perf-review | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| risk-scaled-review-trigger-plan-wording | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| risk-scaled-review-trigger-ready-to-merge | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.35 | positive: fired 3/3 |
| risk-scaled-review-trigger-review-before-merge | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.38 | positive: fired 3/3 |
| risk-scaled-review-trigger-revisa-pr-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.51 | positive: fired 3/3 |
| risk-scaled-review-trigger-second-pair | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.38 | positive: fired 3/3 |
| risk-scaled-review-trigger-security-focus | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.47 | positive: fired 3/3 |
| risk-scaled-review-trigger-summarize-pr | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| risk-scaled-review-trigger-typo-branch | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.35 | positive: fired 3/3 |

## Rerun after scenario and grader fixes (sonnet)

`risk-scaled-review-behavior-clean-diff-no-high-findings`: 0.50 → 1.00 (3 runs, delta 0.00, $1.09). The scaffold now records green evidence at the branch head, which the review package requires. The suite rows above are from the earlier run.
