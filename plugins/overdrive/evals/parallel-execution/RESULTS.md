# Eval results: parallel-execution

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.50, cases passed 23/24, cost $13.70, 955s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 12/12 (100%)
- Trigger accuracy (validation): 8/8 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| parallel-execution-behavior-conflict-is-serialized | behavior | 1.00 | 0.57 | +0.43 | 3 | $0.62 |  |
| parallel-execution-behavior-integrates-and-tests | behavior | 1.00 | 0.56 | +0.44 | 3 | $0.51 |  |
| parallel-execution-behavior-refuses-overlap | behavior | 1.00 | 0.50 | +0.50 | 3 | $1.32 |  |
| parallel-execution-behavior-uses-worktrees | behavior | 1.00 | 0.11 | +0.89 | 3 | $2.89 |  |
| parallel-execution-trigger-both-finish | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.46 | positive: fired 3/3 |
| parallel-execution-trigger-ci-jobs | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| parallel-execution-trigger-concurrent-order | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| parallel-execution-trigger-es-builders | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| parallel-execution-trigger-es-no-se-pisan | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.43 | positive: fired 3/3 |
| parallel-execution-trigger-es-plimit | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| parallel-execution-trigger-es-sequential | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.41 | negative: fired 0/3 |
| parallel-execution-trigger-es-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| parallel-execution-trigger-fan-out | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| parallel-execution-trigger-integrate | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.45 | positive: fired 3/3 |
| parallel-execution-trigger-merge-conflict | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| parallel-execution-trigger-own-worktree | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.39 | positive: fired 3/3 |
| parallel-execution-trigger-promise-all | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| parallel-execution-trigger-tests-parallel | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.40 | negative: fired 0/3 |
| parallel-execution-trigger-three-independent | trigger | 0.67 | 0.00 | +0.67 | 3 | $0.43 | positive: fired 2/3 |
| parallel-execution-trigger-three-slices | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.42 | positive: fired 3/3 |
| parallel-execution-trigger-vendors | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.80 | negative: fired 0/3 |
| parallel-execution-trigger-worker-pool | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| parallel-execution-trigger-worktree-explain | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| parallel-execution-trigger-xargs | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
