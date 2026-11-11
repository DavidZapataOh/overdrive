# Eval results: decision-log

- Date: 2026-11-10
- Claude Code: 2.1.322
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.92, mean delta +0.41, cases passed 21/24, cost $10.97, 784s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 10/10 (100%)
- Trigger accuracy (validation): 8/10 (80%), floor 90%: FAIL

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| decision-log-behavior-copy-respects-claude-md | behavior | 0.75 | 0.75 | 0.00 | 3 | $0.45 |  |
| decision-log-behavior-dispatch-carries-rules | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.78 |  |
| decision-log-behavior-flags-scope-cut | behavior | 0.92 | 0.75 | +0.17 | 3 | $0.48 |  |
| decision-log-behavior-records-verbatim-scope | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.45 |  |
| decision-log-trigger-anota-precio-3 | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.50 | positive: fired 3/3 |
| decision-log-trigger-billing-pr-body-2 | trigger | 0.33 | 0.00 | +0.33 | 3 | $0.49 | positive: fired 1/3 |
| decision-log-trigger-board-research-6 | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.37 | positive: fired 3/3 |
| decision-log-trigger-cambio-de-opinion-es | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.60 | positive: fired 3/3 |
| decision-log-trigger-decided-typo | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.57 | positive: fired 3/3 |
| decision-log-trigger-decision-tree | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.74 | negative: fired 0/3 |
| decision-log-trigger-decisions-table | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.44 | negative: fired 0/3 |
| decision-log-trigger-explain-code | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |
| decision-log-trigger-git-log | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.33 | negative: fired 0/3 |
| decision-log-trigger-keep-postgres-4 | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.51 | positive: fired 3/3 |
| decision-log-trigger-landing-copy | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.61 | positive: fired 3/3 |
| decision-log-trigger-release-changelog-4 | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.30 | negative: fired 0/3 |
| decision-log-trigger-rename-log-fn-3 | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.34 | negative: fired 0/3 |
| decision-log-trigger-reply-after-subagents | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.47 | positive: fired 3/3 |
| decision-log-trigger-send-final-plan | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.41 | positive: fired 3/3 |
| decision-log-trigger-sentry-errors-3 | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.37 | negative: fired 0/3 |
| decision-log-trigger-spanish-email-reply | trigger | 0.00 | 0.00 | 0.00 | 3 | $0.42 | positive: fired 0/3 |
| decision-log-trigger-test-parse-decision | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| decision-log-trigger-typo-hero-copy | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.35 | negative: fired 0/3 |
| decision-log-trigger-what-is-adr | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.32 | negative: fired 0/3 |

## Rerun after scenario and grader fixes (sonnet)

`decision-log-behavior-copy-respects-claude-md`: 0.75 → 1.00 (3 runs, delta 0.00, $0.50). The `no-human-contact` grader now ignores negations ("sin agendar", "nada que agendar") and competitor contrast, and still fails on an offer ("agendemos una llamada", "reserva una demo"). The suite rows above are from the earlier run.
