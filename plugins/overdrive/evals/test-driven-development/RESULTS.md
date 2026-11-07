# Eval results: test-driven-development (smoke)

Smoke numbers only: one run per case on the with arm, no baseline arm, nothing averaged. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh test-driven-development --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-07
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5
- Judge model: none (smoke uses free graders only)

## Trigger set (1 run per case, 20 cases)

| Set | Result |
| --- | --- |
| should-trigger (10) | 0/10 fired |
| should-not-trigger (10) | 10/10 stayed out |

Three descriptions were tried, each over the whole set: a general "implementing a feature or fix" wording, one that says it applies in every risk lane, and the classic "use when implementing any feature or bugfix, before writing implementation code" wording. All gave the same 0/10. Cases that name the skill load it. The model reads the files, classifies the change with `overdrive risk` and writes the test itself, without calling the Skill tool. In a scratch copy of the plugin, a session-start text that tells the model to call the Skill tool in every lane raised it to 1/10. Triggering depends on the routing text and the description together, so the description tuning rounds (train failures only, five at most) have not been run.

## Behavior cases (1 run each, skill not loaded unless the prompt names it)

| Case | Natural prompt | Prompt starts with `/overdrive:test-driven-development` |
| --- | --- | --- |
| test-before-code | 0.5 | 0.0 |
| pinned-test-not-edited-in-green | 0.0 | 0.0 |
| config-change-is-tdd-na | 0.5 | 0.5 |
| critical-has-non-regression | 0.5 | 0.5 |

With the skill loaded the model follows the cycle: it writes the tests, commits them, pins them and runs `overdrive evidence red`, reads `references/non-regression.md` on the critical case and adds hard cases. Then every `overdrive` command that writes under `.overdrive/run/` fails in the eval Bash sandbox of the machine used here (`mktemp: ... Read-only file system`, `mkdir: cannot create directory ... Read-only file system`), the model stops before implementing, and the graders that need the implementation or the closing line fail. These numbers say nothing about the skill until the sandbox allows writes; they were not rerun on a different machine.

## Pressure scenarios (hand-read)

| Scenario | Without | With (skill loaded) |
| --- | --- | --- |
| demo-in-20 | 4/5 compliant | 3/3 compliant |
| already-wrote-200-lines | 1/5 compliant | 3/3 compliant, after one rule change |
| test-is-annoying | 5/5 compliant | 3/3 compliant |

## Cost

Baselines about $0.9 and pressure with the skill about $0.7 (sonnet, read-only tools); trigger smoke about $1.0 per pass over five passes including the diagnostics; behavior smoke about $1.1 over three passes; about $8 in total.
