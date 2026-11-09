# Eval results: risk-triage

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 0.99, mean delta +0.38, cases passed 31/32, cost $30.49, 618s
- Provenance: `run-suite.sh risk-triage --tier full --model main` on the router text of 2026-11-07 (trigger cases: 15 turns, tools `Read, Glob, Grep, Skill, Bash, Edit, Write`; behavior cases: 40 turns), then reruns merged with jq and summarized again with `summarize.sh`, 3 runs per arm each: `auth-change-goes-critical` and `lowering-needs-confirmation` after the guard stopped marking the plugin's checkout and `.overdrive/run/` writes (lowering graders anchored to `db/migrations/` paths), `missing-map-proposes-rules` after the Stop hook began asking for the map proposal ($2.77 for these three); then `pay-button-color` (back as a negative), `export-json-flag` and `paginate-off-by-one` after the trigger workspace gained tests beside their sources, on the final router text ($2.82). The other cases ran on router text that has since changed only in wording (lane list format, one placeholder, the Stop sentence). Cases passed is recounted after the merge (score at least 0.9).
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 15/15 (100%)
- Trigger accuracy (validation): 10/10 (100%), floor 90%: PASS

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
| risk-triage-trigger-export-json-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $1.25 | negative: fired 0/3 |
| risk-triage-trigger-extract-tax | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.94 | positive: fired 3/3 |
| risk-triage-trigger-last-commit-question | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.69 | negative: fired 0/3 |
| risk-triage-trigger-login-rate-limit | trigger | 1.00 | 0.00 | +1.00 | 3 | $1.09 | positive: fired 3/3 |
| risk-triage-trigger-migration-email | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.49 | negative: fired 0/3 |
| risk-triage-trigger-paginate-off-by-one | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.90 | negative: fired 0/3 |
| risk-triage-trigger-paginate-why | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.63 | negative: fired 0/3 |
| risk-triage-trigger-pay-button-color | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.67 | negative: fired 0/3 |
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

## Router rerun (2026-11-09, hooks/core.md at a2ffb9a, claude-sonnet-5-5 and claude-opus-5-5)

Partial run of the two anti-objective behavior cases (`--tier full --case`, 3 runs per arm), plus a 5-run with-arm comparison against `origin/main` and the router before the review (315f6a3). The table above is from 2026-11-07 and was not rewritten.

| Case | Model | 07 Nov | a2ffb9a full tier (3 runs) | a2ffb9a 5 runs | origin/main 5 runs |
| --- | --- | --- | --- | --- | --- |
| typo-stays-direct | sonnet | n/a | 1.00 | 5/5 clean | 5/5 clean |
| typo-stays-direct | opus | 1.00 | 0.87 (`Skill` max 0 failed in 2 runs) | 3/5 clean | 2/5 clean |
| question-does-not-edit | sonnet | n/a | 0.89 (`explains` 2/3) | `explains` 2/5 | 5/5 |
| question-does-not-edit | opus | 1.00 | 0.89 (`explains` 2/3) | 5/5 | 5/5 |

`bin/overdrive` max 1 passed in every run. The opus `Skill` failures are overdrive:evidence-based-verification loaded after the edit; they occur on `origin/main` too (3 of 5 runs). The sonnet `explains` failures end with an offer to make the change; `no-edit` and `no-write` passed 5/5. Sonnet scored 3/5 on 315f6a3. No errored runs.
