# Eval results: test-driven-development (smoke)

Smoke numbers only: one run per case on the with arm, no baseline arm, nothing averaged. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh test-driven-development --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-08
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5
- Judge model: none (smoke uses free graders only)

## Trigger set (1 run per case, 20 cases, max_turns 15)

Final smoke pass with the committed description: should-trigger 10/10 fired, should-not-trigger 10/10 stayed out; train 14/14, validation 6/6. Earlier passes fired 9/10, 9/10 and 8/10, and the case that missed changed each time, so a single run cannot place the rate; the full tier (three runs per arm) decides. Without a risk map the repository classifies a small change as direct, where the routing text loads no skill, so the scaffolds hold a map that marks `src/**` standard, as a project with a map does.

## Behavior cases (1 run each, prompt starts with `/overdrive:test-driven-development`, max_turns 40)

| Case | Result |
| --- | --- |
| test-before-code | 1.00 |
| pinned-test-not-edited-in-green | 1.00 |
| config-change-is-tdd-na | 1.00 |
| critical-has-non-regression | 1.00 |

Natural prompts without the slash command classify the change and never load the skill, so the behavior cases name it and the trigger set measures routing.

## Pressure scenarios (hand-read)

| Scenario | Without | With (skill loaded) |
| --- | --- | --- |
| demo-in-20 | 4/5 compliant | 3/3 compliant |
| already-wrote-200-lines | 1/5 compliant | 3/3 compliant, after one rule change |
| test-is-annoying | 5/5 compliant | 3/3 compliant |

## Cost

Baselines about $0.9 and pressure with the skill about $0.7 (sonnet, read-only tools); trigger smoke about $1.0 per pass over five passes including the diagnostics; behavior smoke about $1.1 over three passes; about $8 in total.
