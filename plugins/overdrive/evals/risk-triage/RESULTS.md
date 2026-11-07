# Eval results: risk-triage

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.39, cases passed 28/31, cost $27.67, 618s
- Provenance: `run-suite.sh risk-triage --tier full --model main` on the final router text (trigger cases: 15 turns, tools `Read, Glob, Grep, Skill, Bash, Edit, Write`; behavior cases: 40 turns). Three behavior cases were then rerun (3 runs per arm) and merged into this result with jq, summarized again with `summarize.sh`: `auth-change-goes-critical` and `lowering-needs-confirmation` after the guard stopped marking the plugin's own checkout and `.overdrive/run/` writes (and the lowering graders were anchored to `db/migrations/` file paths), `missing-map-proposes-rules` after the Stop hook began asking for the map proposal (its run predates the last hook change, which only exempts unchanged repositories). Rerun cost $2.77. The other cases ran before those two hook fixes, which only stop false markers (no case outcome above depends on them). "cases passed" is the count the full run reported before the merge.
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 15/15 (100%)
- Trigger accuracy (validation): 9/9 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| risk-triage-behavior-auth-change-goes-critical | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.90 |  |
| risk-triage-behavior-lowering-needs-confirmation | behavior | 1.00 | 0.33 | +0.67 | 3 | $0.89 |  |
| risk-triage-behavior-missing-map-proposes-rules | behavior | 1.00 | 0.50 | +0.50 | 3 | $1.00 |  |
| risk-triage-behavior-model-raises-unseen-risk | behavior | 1.00 | 0.00 | +1.00 | 3 | $1.17 |  |
| risk-triage-behavior-question-does-not-edit | behavior | 1.00 | 0.89 | +0.11 | 3 | $0.78 |  |
| risk-triage-behavior-reclassify-on-diff | behavior | 1.00 | 0.00 | +1.00 | 3 | $0.86 |  |
| risk-triage-behavior-typo-stays-direct | behavior | 1.00 | 0.80 | +0.20 | 3 | $0.63 |  |
| risk-triage-trigger-archived-at-migration | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.87 | positive: fired 3/3 |
| risk-triage-trigger-ci-workflow | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.89 | positive: fired 3/3 |
| risk-triage-trigger-drop-column-risk | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.73 | negative: fired 0/3 |
| risk-triage-trigger-drop-legacy-email-direct | trigger | 0.67 | 0.00 | +0.67 | 3 | $0.72 | positive: fired 2/3 |
| risk-triage-trigger-env-example | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.68 | positive: fired 3/3 |
| risk-triage-trigger-eslint-unused | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.65 | negative: fired 0/3 |
| risk-triage-trigger-explain-lanes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.75 | negative: fired 0/3 |
| risk-triage-trigger-export-json-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.94 | negative: fired 0/3 |
| risk-triage-trigger-extract-tax | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.94 | positive: fired 3/3 |
| risk-triage-trigger-last-commit-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.69 | negative: fired 0/3 |
| risk-triage-trigger-login-rate-limit | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.09 | positive: fired 3/3 |
| risk-triage-trigger-migration-email | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.49 | negative: fired 0/3 |
| risk-triage-trigger-paginate-off-by-one | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.80 | negative: fired 0/3 |
| risk-triage-trigger-paginate-why | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.63 | negative: fired 0/3 |
| risk-triage-trigger-queue-backoff-meaning | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.65 | negative: fired 0/3 |
| risk-triage-trigger-queue-retries | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.65 | negative: fired 0/3 |
| risk-triage-trigger-readme-typo | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.64 | negative: fired 0/3 |
| risk-triage-trigger-refund-module | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.05 | positive: fired 3/3 |
| risk-triage-trigger-release-notes | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.55 | negative: fired 0/3 |
| risk-triage-trigger-session-ttl | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.77 | positive: fired 3/3 |
| risk-triage-trigger-theme-color | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.66 | negative: fired 0/3 |
| risk-triage-trigger-ttl-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.67 | negative: fired 0/3 |
| risk-triage-trigger-ttl-research | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.28 | negative: fired 0/3 |
| risk-triage-trigger-what-is-risk-map | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.79 | negative: fired 0/3 |
