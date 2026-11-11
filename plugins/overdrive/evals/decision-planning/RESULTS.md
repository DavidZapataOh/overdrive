# Eval results: decision-planning

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.47, cases passed 26/26, cost $11.93, 834s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 11/11 (100%)
- Trigger accuracy (validation): 9/9 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| decision-planning-behavior-critical-waits-approval | behavior | 1.00 | 0.43 | +0.57 | 3 | $0.72 |  |
| decision-planning-behavior-direct-no-plan | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.34 |  |
| decision-planning-behavior-respects-show-plans-all | behavior | 1.00 | 0.42 | +0.58 | 3 | $0.55 |  |
| decision-planning-behavior-respects-show-plans-default | behavior | 1.00 | 0.75 | +0.25 | 3 | $0.55 |  |
| decision-planning-behavior-skeleton-first | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.65 |  |
| decision-planning-behavior-standard-no-code-bodies | behavior | 1.00 | 0.75 | +0.25 | 3 | $0.60 |  |
| decision-planning-trigger-break-into-tasks | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.53 | positive: fired 3/3 |
| decision-planning-trigger-continuar-plan-es | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.41 | negative: fired 0/3 |
| decision-planning-trigger-execute-plan | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.38 | negative: fired 0/3 |
| decision-planning-trigger-explain-code | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| decision-planning-trigger-fix-bug | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| decision-planning-trigger-how-to-approach | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.51 | positive: fired 3/3 |
| decision-planning-trigger-plan-es-detalle | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.59 | positive: fired 3/3 |
| decision-planning-trigger-plan-feature | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.56 | positive: fired 3/3 |
| decision-planning-trigger-plan-for-skeleton | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.45 | positive: fired 3/3 |
| decision-planning-trigger-plan-today | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| decision-planning-trigger-plan-travel | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| decision-planning-trigger-plan-wording | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| decision-planning-trigger-planifica-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.44 | positive: fired 3/3 |
| decision-planning-trigger-rename-var | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| decision-planning-trigger-review-branch | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| decision-planning-trigger-revise-plan | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| decision-planning-trigger-roadmap-dates | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| decision-planning-trigger-roadmap-slices | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| decision-planning-trigger-scope-v1 | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.48 | positive: fired 3/3 |
| decision-planning-trigger-tdd-plan | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.64 | positive: fired 3/3 |
