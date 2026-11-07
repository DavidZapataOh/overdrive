# Evaluation

Every skill is measured with `claude plugin eval` before it ships: does Claude pick the skill when it should (trigger), does it behave better with the skill than without it (behavior), and does it hold under pressure to cut corners (pressure). This page covers how the suites are laid out, how to run them, and what was verified about the runner itself.

Everything below was verified against Claude Code 2.1.319. CI installs exactly that version (`OD_EVAL_CLAUDE_VERSION` in `tools/evals/models.env`) and `summarize.sh` refuses results from any other version until the result format is re-verified and the pin is updated.

Reference: [Test plugins with evals](https://code.claude.com/docs/en/plugin-evals) (Claude Code 2.1.319). Every key used in a case below is taken from that page.

## Layout

```
plugins/overdrive/evals/
  _lib/fixtures.sh                       # sourced by scaffold scripts
  <skill>/
    RESULTS.md                           # written by run-suite.sh --tier full
    trigger/<skill>-trigger-<slug>/      # prompt.md + graders/
    behavior/<skill>-behavior-<slug>/    # case.yaml + prompt.md + scaffold.sh + graders/
    pressure/<scenario>/                 # case.yaml + prompt.md + scaffold.sh + graders/
  results/                               # runner output, gitignored
tests/pressure/<skill>/<scenario>/       # scenario.md, baseline.md, after.md
tests/pressure/<skill>/<scenario>/runs/  # final messages of each run, gitignored
```

### Naming and tags

The directory name is the case name. `--case` matches only the case name, never the path, and `--tag` keeps a case that has any of the listed tags, so the tooling selects by tag and uses `--case` to narrow to one scenario. Every case carries:

| Tag | On |
| --- | --- |
| `<skill>-trigger`, `<skill>-behavior`, `<skill>-pressure` | the matching tier |
| `<skill>-smoke` | the cases that use free graders only (`regex`, `tool_used`, `tool_order`, `file_exists`) |
| `train` or `validation` | trigger cases, added by `tools/evals/split-trigger-set.sh` |

The tags line in `prompt.md` must be a flow list (`tags: [tdd-trigger, tdd-smoke]`). `tools/check-skills.sh` fails a `*-smoke` case that has an `llm` or `baseline` grader.

### Trigger cases

One `prompt.md` and one grader. The prompt is phrased the way a person types it, without naming the skill.

```markdown
---
max_turns: 5
allowed_tools: [Read, Skill]
tags: [tdd-trigger, tdd-smoke]
---
My parser drops the last token when the input has no trailing newline. Can you fix it?
```

A positive case passes when the skill fires:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?tdd"'
---
```

A negative case (the skill must stay out of the way) adds `min: 0`, `max: 0` and `arm: both`. The summarizer recognizes a negative case by `max: 0`.

Run `tools/evals/split-trigger-set.sh plugins/overdrive/evals/<skill>/trigger` after adding cases. The `skill-evaluation` skill ships the same script as `scripts/split-trigger-set`; CI fails if the two copies differ. A case goes to `train` for 60 of every 100 checksums of its name, so adding or removing cases never moves another one. Description edits are tuned on `train`; `validation` is the number that counts.

### Behavior and pressure cases

A case that needs files or a repository has a `case.yaml` (`schema_version: "1.1"`, `name` equal to the directory name, `context.scaffold_script`) and a scaffold script that builds the workspace with the fixture library:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project billing
fx_file src/refund.js 'module.exports = () => 0;'
fx_risk_map 'pathtoken refund money'
fx_commit "Add refund stub"
```

| Function | Result |
| --- | --- |
| `fx_git_repo` | `git init` on `main` in the current directory, with a local identity |
| `fx_node_project NAME` | `package.json` with `"test": "node --test"`; nothing is installed |
| `fx_file PATH CONTENT` | the file, with its directories |
| `fx_plugin NAME [DESCRIPTION]` | a Claude Code plugin at the workspace root: `.claude-plugin/plugin.json` and an empty `skills/` |
| `fx_commit MSG` | stage everything and commit (an empty commit is allowed) |
| `fx_risk_map RULE...` | `.overdrive/risk-map.conf`, one rule per argument |
| `fx_decisions ENTRY...` | `.overdrive/decisions.md`, one complete `## D-NNNN` entry per argument |
| `fx_claude_md TEXT` | `CLAUDE.md` as an ordinary file the skill has to read; eval runs never load it as project configuration |

Give each case one grader on the result and one on the steps taken. Prefer `regex` over files to `llm`; keep `llm` rubrics to short outputs with concrete PASS and FAIL conditions.

## Running

```bash
tools/evals/run-suite.sh SKILL --tier smoke|full|pressure [--model main|sonnet] [--max-cost-usd N] [--concurrency N] [--allow-tools TOOL...]
```

| Tier | What runs | Default ceiling |
| --- | --- | --- |
| `smoke` | cases tagged `<skill>-smoke`, one run, no baseline arm, no judge | $2 |
| `full` | trigger and behavior cases, three runs per arm with and without the plugin, `--threshold 0.9`, judge model pinned | $25 |
| `pressure` | each scenario with the plugin, five runs, final messages kept | $15 per scenario |

`full` writes `plugins/overdrive/evals/<skill>/RESULTS.md` unless the run was partial: date, Claude Code version, pinned model IDs, trigger accuracy for `train` and `validation` (floor 90% on validation), per-case score, baseline score, delta and cost, a `REGRESSION` note on every case with a negative delta, and a list of cases with errored runs. A case whose runs did not all grade counts as an incorrect trigger case, and `run-suite.sh` exits 1 when any run errored. The release rules for a skill are in the plan; the summary only reports them.

Pressure scenarios are read by hand. `tools/evals/pressure.sh SKILL SCENARIO --arm with|without` writes each run's final message to `tests/pressure/<skill>/<scenario>/runs/<arm>-<n>.md` and prints the cost and duration of the batch. New skills are built with the `skill-evaluation` skill (`/overdrive:skill-evaluation <name>`); `scripts/new-pressure-case SKILL SCENARIO` in that skill scaffolds `scenario.md` and the pressure case. The `without` arm runs the same scenario under an empty plugin, because the CLI cannot run a baseline arm alone.

Local requirements: `jq`, Node 22 or later for `fx_node_project` cases, and, for cases that grant `Bash`, `bubblewrap` and `socat` (the run is refused without a sandbox) and a `PATH` without unreadable directories.

### Models

`tools/evals/models.env` pins full model IDs from the [models overview](https://platform.claude.com/docs/en/about-claude/models/overview) (checked 2026-11-07 UTC; dateless IDs are pinned snapshots):

| Variable | Value | Used for |
| --- | --- | --- |
| `OD_EVAL_MODEL_MAIN` | `claude-opus-5-5` | the agent under test (`--model main`) |
| `OD_EVAL_MODEL_SONNET` | `claude-sonnet-5-5` | the agent under test (`--model sonnet`) |
| `OD_EVAL_JUDGE` | `claude-sonnet-5-5` | `llm` graders |

The judge is Sonnet rather than the CLI default (Haiku). The `llm` graders decide release thresholds on rubrics about process, and the eval docs warn that a small judge can mark a correct answer wrong over formatting and flip the sign of the delta. The extra cost is a few short calls per graded run.

## CI

`.github/workflows/evals.yml` runs the smoke tier on a pull request for each skill whose files changed (same-repository branches only; a change to shared plugin code, the fixtures or the eval tools selects every skill with cases), and the full tier on a `v*` tag, weekly, and on demand. Without `ANTHROPIC_API_KEY` (not yet configured, and always absent on forks) the workflow ends green with a notice annotation and a step summary saying the evals were skipped. Results are uploaded as artifacts.

## What was verified about the runner

Spike on Claude Code 2.1.319, 2026-11-07 (UTC, from the recorded result), with a throwaway plugin copy outside the repository (cost under $0.03 in total, model `claude-haiku-5-5`). The recorded result document is `tests/evals/fixtures/aggregate-result.recorded.json`, with local paths replaced by placeholders.

**Scaffold scripts can source `_lib/fixtures.sh` by relative path.** `$0` is the absolute path of the script inside the case directory of the plugin, so `$(dirname "$0")/../../../_lib/fixtures.sh` resolves from `evals/<skill>/<tier>/<case>/`. The script runs in the empty workspace (`.../home/cwd`) and needs `--scaffold`.

**Where results live.**

| Need | Location |
| --- | --- |
| Per-run score, turns, cost, duration, error | `cases[].arms.with[]` and `.without[]`: `score`, `turns`, `costUsd`, `judgeCostUsd`, `durationSeconds`, `error`, `skippedPaidGraders` |
| Grader verdicts | `arms.*[].graders[]`: `name`, `passed`, `weight`, `explanation`, `scored`, `withOnly`; the definitions are in `cases[].graders[]` (`type`, `config`) |
| Trigger result | the `tool_used` grader with `config.tool == "Skill"`; `passed` is per run. A negative case has `config.max == 0` |
| Case score and delta | `cases[].aggregates`: `score`, `scoreWithout`, `delta`, `passRate`; suite: `aggregates.overallScore`, `meanDelta`, `casesPassed`, `casesTotal` |
| Suite cost and time | top level `costUsd`, `durationSeconds`, `claudeVersion`, `startedAt`, `partial` |
| Final assistant message, tokens | not in the JSON. `arms.*[].tracePath` points to a `trace.jsonl` whose last line has `type == "result"` with `.result`, `.usage`, `.total_cost_usd`, `.duration_ms`, `.num_turns`. The file is deleted unless `--keep-temp` is passed, and a kept directory is sealed (mode 0500, with a mode 000 subdirectory), so it needs `chmod -R u+rwx` before removal |

A `tool_used: Skill` grader is excluded from the score (`scored: false`) in a two-arm run only when the case has other graders; alone, it is scored normally.

**Plugin hooks run in the with-arm; `bin/` is not on the Bash tool's `PATH`.** A `SessionStart` hook ran with the plugin loaded (`hook_started` and `hook_response` records in the trace), its `additionalContext` reached the model, and the same prompt in the baseline arm did not see it. The hook ran in the workspace with `CLAUDE_PLUGIN_ROOT` set, but `overdrive` was not on its `PATH`. With `Bash` granted, `command -v overdrive` found nothing and `CLAUDE_PLUGIN_ROOT` was not set in the tool's shell. Consequence: skills call the CLI by absolute path (`${CLAUDE_PLUGIN_ROOT}/bin/overdrive`, substituted in skill content) and the session-start router text uses the substituted root, never the bare command name.

The plugin in this repository has no hooks yet; the hook probe used a temporary one in the throwaway copy.
