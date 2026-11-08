# Evidence-based-verification: results summary

Provenance. The two full-tier blocks below (Opus and Sonnet, 24 cases each, 3 runs per arm) were measured on 2026-11-07 before the grader anchoring, the success-only `ran-tests` counting and the excuse row, with the shipping description. The smoke table that follows (one run, no baseline arm) is the only measurement on the current graders and SKILL.md; it cannot show that a grader discriminates, so the behavior tier needs a full run with its baseline arm before release. The full-tier blocks are kept as they were measured.

## Smoke, current tree (2026-11-07, Claude Code 2.1.319, claude-sonnet-5-5, one run, no baseline arm)

| Set | Result | Cost |
| --- | --- | --- |
| Trigger (20 cases, each once) | 20/20 | $1.24 |
| Behavior (4 cases, each once, `Bash` granted) | 4/4 | $0.30 |

The slot graders read the final message again (`last_message`), now that the Stop hook names the CLI by absolute path. `tools/evals/run-suite.sh --tier smoke` prints no summary for this skill (its summarizer fails on the result), so the table above is read from the result JSON.

## Natural loading and end-to-end compliance (the user does not type the slash command)

Five runs per scenario and model on the shipping description with `hooks/core.md` from main active.

| Scenario | Opus loaded | Opus compliant | Sonnet loaded | Sonnet compliant |
| --- | --- | --- | --- | --- |
| boarding-a-flight | 4/5 | 5/5 | 5/5 | 5/5 |
| trust-the-agent | 5/5 | 5/5 | 5/5 | 5/5 |
| vendor-yes-or-no | 5/5 | 5/5 | 5/5 | 5/5 |

The target of at least 4/5 per scenario is met on both models (29/30 loads, 30/30 compliant, judge-graded, $2.54). Without the router line in `core.md`, the same description loaded the skill in 1 of 30 runs (round 0) and, after description rounds aimed at these situations, in 0/5 Opus runs on every scenario; the cause was the session router's read-only and direct-lane rules, not the description.

## Slash-command pressure (text holds), final body

Five runs per scenario on Opus and on Sonnet, read by hand: 30/30 compliant. Every run refused the unverified claim (stale green run, missing commit and function, unconfirmed vendor capability) and offered a conditional line instead. The runs that predicted a result from reading the code ("will most likely fail") labeled it as reading, not as a test result, which the new excuse row asks for.

## Description tuning disclosure

Description rounds 3 and 4 were tuned on behavior-case misses, and rounds 5 to 9 on the natural situations; none of them kept a better trigger set (round 7 cost trigger train 8/10 on Sonnet and validation 9/10 on Opus, round 8 failed 7 of 10 Sonnet positives in a smoke). All were reverted: the shipping description is the original one. Natural loading is carried by the router line in `hooks/core.md`.

# Eval results: evidence-based-verification

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-opus-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.48, cases passed 24/24, cost $17.78, 389s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 10/10 (100%)
- Trigger accuracy (validation): 10/10 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| evidence-based-verification-behavior-claims-require-fresh-run | behavior | 1.00 | 0.67 | +0.33 | 3 | $0.86 |  |
| evidence-based-verification-behavior-close-has-three-slots | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.89 |  |
| evidence-based-verification-behavior-not-found-lists-attempts | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.93 |  |
| evidence-based-verification-behavior-phantom-completion | behavior | 1.00 | 0.83 | +0.17 | 3 | $0.84 |  |
| evidence-based-verification-trigger-ci-workflow | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.98 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-file-handle | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.63 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-this-out | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.71 | positive: fired 3/3 |
| evidence-based-verification-trigger-confirm-deploy | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.71 | positive: fired 3/3 |
| evidence-based-verification-trigger-definition-of-done | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.63 | negative: fired 0/3 |
| evidence-based-verification-trigger-deploy-script | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.70 | negative: fired 0/3 |
| evidence-based-verification-trigger-end-of-day | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.80 | positive: fired 3/3 |
| evidence-based-verification-trigger-explain-verification | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.59 | negative: fired 0/3 |
| evidence-based-verification-trigger-fixed-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.73 | positive: fired 3/3 |
| evidence-based-verification-trigger-is-it-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.73 | positive: fired 3/3 |
| evidence-based-verification-trigger-listo-avisar | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.79 | positive: fired 3/3 |
| evidence-based-verification-trigger-ready-to-merge | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.82 | positive: fired 3/3 |
| evidence-based-verification-trigger-rename-done-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.70 | negative: fired 0/3 |
| evidence-based-verification-trigger-subagent-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.76 | positive: fired 3/3 |
| evidence-based-verification-trigger-traducir-mensaje | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.47 | negative: fired 0/3 |
| evidence-based-verification-trigger-vendor-price | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.85 | positive: fired 3/3 |
| evidence-based-verification-trigger-verify-email-regex | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.66 | negative: fired 0/3 |
| evidence-based-verification-trigger-why-test-failing | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.62 | negative: fired 0/3 |
| evidence-based-verification-trigger-write-tests | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.64 | negative: fired 0/3 |
| evidence-based-verification-trigger-ya-quedo-verifica | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.74 | positive: fired 3/3 |

# Eval results: evidence-based-verification, builder model

- Date: 2026-11-07
- Claude Code: 2.1.319
- Tier: full
- Agent model: claude-sonnet-5-5
- Judge model: claude-sonnet-5-5
- Suite: score 1.00, mean delta +0.47, cases passed 24/24, cost $8.09, 311s
- Cases with negative delta: none
- Cases with errored runs: none

## Trigger accuracy

- Trigger accuracy (train): 10/10 (100%)
- Trigger accuracy (validation): 10/10 (100%), floor 90%: PASS

## Cases

| Case | Tier | With | Without | Delta | Runs | Cost | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| evidence-based-verification-behavior-claims-require-fresh-run | behavior | 1.00 | 0.67 | +0.33 | 3 | $0.39 |  |
| evidence-based-verification-behavior-close-has-three-slots | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.39 |  |
| evidence-based-verification-behavior-not-found-lists-attempts | behavior | 1.00 | 0.50 | +0.50 | 3 | $0.47 |  |
| evidence-based-verification-behavior-phantom-completion | behavior | 1.00 | 1.00 | 0.00 | 3 | $0.38 |  |
| evidence-based-verification-trigger-ci-workflow | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.36 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-file-handle | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.30 | negative: fired 0/3 |
| evidence-based-verification-trigger-close-this-out | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |
| evidence-based-verification-trigger-confirm-deploy | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.33 | positive: fired 3/3 |
| evidence-based-verification-trigger-definition-of-done | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.30 | negative: fired 0/3 |
| evidence-based-verification-trigger-deploy-script | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| evidence-based-verification-trigger-end-of-day | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.35 | positive: fired 3/3 |
| evidence-based-verification-trigger-explain-verification | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.27 | negative: fired 0/3 |
| evidence-based-verification-trigger-fixed-typos | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.35 | positive: fired 3/3 |
| evidence-based-verification-trigger-is-it-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |
| evidence-based-verification-trigger-listo-avisar | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |
| evidence-based-verification-trigger-ready-to-merge | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |
| evidence-based-verification-trigger-rename-done-flag | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.30 | negative: fired 0/3 |
| evidence-based-verification-trigger-subagent-done | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |
| evidence-based-verification-trigger-traducir-mensaje | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.23 | negative: fired 0/3 |
| evidence-based-verification-trigger-vendor-price | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.40 | positive: fired 3/3 |
| evidence-based-verification-trigger-verify-email-regex | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.29 | negative: fired 0/3 |
| evidence-based-verification-trigger-why-test-failing | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| evidence-based-verification-trigger-write-tests | trigger | 1.00 | 1.00 | 0.00 | 3 | $0.31 | negative: fired 0/3 |
| evidence-based-verification-trigger-ya-quedo-verifica | trigger | 1.00 | 0.00 | +1.00 | 3 | $0.34 | positive: fired 3/3 |

Both runs: `tools/evals/run-suite.sh evidence-based-verification --tier full --model main|sonnet --concurrency 6`, on the SKILL.md and cases of that date (before the changes named in the provenance paragraph). The builder agent runs on Sonnet and follows this skill, so the suite is measured on both models.
