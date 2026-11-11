# Evaluation

Every skill is measured with `claude plugin eval` before it ships: does Claude pick the skill when it should (trigger), does it behave better with the skill than without it (behavior), and does it hold under pressure to cut corners (pressure). This page covers how the suites are laid out, how to run them, and what was verified about the runner itself.

Everything below was verified against Claude Code 2.1.322. CI installs exactly that version (`OD_EVAL_CLAUDE_VERSION` in `tools/evals/models.env`) and `summarize.sh` refuses results from any other version until the result format is re-verified and the pin is updated.

Reference: [Test plugins with evals](https://code.claude.com/docs/en/plugin-evals) (Claude Code 2.1.319). Every key used in a case below is taken from that page.

## Layout

```
plugins/overdrive/evals/
  _lib/fixtures.sh                       # sourced by scaffold scripts
  <skill>/
    RESULTS.md                           # written by run-suite.sh --tier full
    trigger/<skill>-trigger-<slug>/      # prompt.md + graders/
    behavior/<skill>-behavior-<slug>/    # case.yaml + prompt.md + scaffold.sh + graders/
    pressure/<skill>-<scenario>/         # case.yaml + prompt.md + scaffold.sh + graders/
    allow-tools                          # tool grants the cases need, one per line
  results/                               # runner output, gitignored
tests/pressure/<skill>/<scenario>/       # scenario.md, baseline.md, after.md
tests/pressure/<skill>/<scenario>/runs/  # runs, gitignored
```

### Naming and tags

The directory name is the case name. `--case` matches only the case name, never the path, and `--tag` keeps a case that has any of the listed tags, so the tooling selects by tag and uses `--case` to narrow to one scenario. Pressure case directories are named `<skill>-<scenario>` so that `--case` never matches another skill's scenario of the same name; `pressure.sh SKILL SCENARIO` and `tests/pressure/<skill>/<scenario>/` use the bare scenario name. Every case carries:

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
| `fx_git_repo` | `git init` on `main` in the current directory, with a local identity, and a local exclude (`.git/info/exclude`) for the placeholders the eval sandbox mounts in the workspace |
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
tools/evals/run-suite.sh SKILL --tier smoke|full|pressure|e2e [--model main|sonnet] [--max-cost-usd N] [--runs N] [--concurrency N] [--case GLOB] [--allow-tools TOOL...]
```

Cases that need tools beyond the read-only set (`Write`, `Edit`, `Bash(...)`) get them from `plugins/overdrive/evals/<skill>/allow-tools`, one grant per line (blank lines and `#` comments are ignored); CI's eval job uses the same file through `run-suite.sh`. `--allow-tools` on the command line replaces the file. `--concurrency N` (1 to 8, not for the pressure tier) runs cases in parallel on one rate limit. `--case GLOB` passes through to `claude plugin eval --case` and narrows the tier to the cases whose name matches, so a fix round reruns only the cases it changed (`run-suite.sh tdd --tier smoke --case 'tdd-behavior-test-*'`); on the pressure tier it selects scenarios by the same name, and a narrowed full run is partial, so it does not write `RESULTS.md`.

| Tier | What runs | Default ceiling |
| --- | --- | --- |
| `smoke` | cases tagged `<skill>-smoke`, one run, no baseline arm, no judge | $2 |
| `full` | trigger and behavior cases, three runs per arm with and without the plugin, `--threshold 0.9`, judge model pinned | $25 |
| `pressure` | each scenario with the plugin, five runs, final messages kept | $15 per scenario |
| `e2e` | the `e2e` suite's behavior cases with the plugin only, three runs (`--runs N` overrides), sandboxes kept so the traces can be read | $30 |

The `e2e` suite (`run-suite.sh e2e --tier e2e`) holds whole-flow cases for each lane, loop detection, CI polling and real worktree dispatch. Each case may run up to an hour and some dispatch opus reviewers, so it is never selected by `changed-skills.sh`, smoke or full, and writes no `RESULTS.md`.

`full` writes `plugins/overdrive/evals/<skill>/RESULTS.md` unless the run was partial: date, Claude Code version, pinned model IDs, trigger accuracy for `train` and `validation` (floor 90% on validation), per-case score, baseline score, delta and cost, a `REGRESSION` note on every case with a negative delta, and a list of cases with errored runs. A case whose runs did not all grade counts as an incorrect trigger case, and `run-suite.sh` exits 1 when any run errored. The release rules for a skill are in the plan; the summary only reports them.

Pressure scenarios are read by hand. `tools/evals/pressure.sh SKILL SCENARIO --arm with|without` writes each run to `tests/pressure/<skill>/<scenario>/runs/<arm>-<n>.md`: every assistant text block in order (`## Assistant text N`), then the final message under `## Final message`, because the Stop hook can request a second reply or replace the last one with a Risk line and prints the cost and duration of the batch. New skills are built with the `skill-evaluation` skill (`/overdrive:skill-evaluation <name>`); `scripts/new-pressure-case SKILL SCENARIO` in that skill scaffolds `scenario.md` and the pressure case. The `without` arm runs the same scenario under an empty plugin, because the CLI cannot run a baseline arm alone.

Local requirements: `jq`, Node 22 or later for `fx_node_project` cases, and, for cases that grant `Bash`, `bubblewrap` and `socat` (the run is refused without a sandbox).

`run-suite.sh` and `pressure.sh` prepare the environment before they call `claude`:

- **Sandbox placeholders in the workspace.** Once a run uses `Bash`, the OS sandbox mounts placeholders in the working directory (`.bashrc`, `.bash_profile`, `.profile`, `.gitconfig`, `.gitmodules`, `.ripgreprc`, `.mcp.json`, `.idea`, `.vscode`, `.claude`, `.eval-artifacts`). Several are `/dev/null` binds, not regular files, so `git add` refuses them and `overdrive risk --worktree` fails closed (`classification-failed`, critical), which makes the Stop hook replace the model's final message. That is the correct behavior for a real repository, so the fix lives in the fixtures: `fx_git_repo` lists the paths in `.git/info/exclude`, and `new-pressure-case` does the same when it falls back to plain `git`. Scaffolds that skip `fx_git_repo` and build a repository by hand must do likewise.
- **Temp tree outside `/tmp` on Linux.** The eval's OS sandbox mounts everything under `/tmp` read-only, so a temp tree there leaves `Bash` in the runs unable to write the workspace or `TMPDIR`. When `TMPDIR` (default `/tmp`) is under `/tmp`, the tools export `TMPDIR="${XDG_CACHE_HOME:-$HOME/.cache}/overdrive-evals/tmp"`. `OVERDRIVE_EVAL_TMPDIR` sets another directory and applies on every platform.
- **Sanitized `PATH`.** Entries that are not readable directories (Windows paths on WSL, missing directories) are dropped, because the CLI refuses to start with them.
- **Grants.** Both tools read `evals/<skill>/allow-tools`; `pressure.sh` has no `--allow-tools` option of its own.

### Deviations of the `e2e` suite from its specification

- **Reviewer counts.** `e2e-standard-feature` allows one or two `overdrive:reviewer` dispatches and `e2e-critical-after-approval` one or two final reviews: the review rules permit one scoped re-review after a fix wave, which is part of the single review of a slice.
- **Trivial change.** `e2e-trivial` passes with no dispatch, no skill call and the single classification. Its recorded cost in tool calls (sonnet, nine kept runs): 3 to 4 tool uses, no Skill calls.
- **Model sweep and model policy.** Running the cases across models and the policy document that follows from it are not part of this suite; they belong to the sweep.
- **Isolation case.** `deep-research-behavior-queries-carry-no-private-names` is a guard rather than a discriminator (see its entry in the deep-research results): the eval workspace does not load CLAUDE.md, so the path through which a subagent receives the project's CLAUDE.md is covered only by the probe recorded in the e2e report (a token in CLAUDE.md reached `general-purpose` and `overdrive:researcher`).

### Graders for the plan ledger

The ledger lives at `.overdrive/run/plan-<cksum>/ledger.md`, where `<cksum>` depends on the plan. `file_exists` takes a glob in `path`, so `path: ".overdrive/run/plan-*/ledger.md"` checks that the ledger was created (only files created during the run count). The docs describe `{ source: file, path }` as the contents of one file and mention no glob for it, so do not rely on a pattern there. To grade the ledger's contents use a `regex` grader with `target: trace` on the output of the ledger command, or have the case call `overdrive ledger path` and grade the path it prints. The run records the plugin's commands in the trace, whose quotes are JSON-escaped. So are its newlines: a command on the second line of a Bash call follows a literal `\n` in the trace text, and `\b` never matches between that `n` and the command's first letter. A trace pattern that anchors on a command name uses `(?:\\[nrt]|\b)` (or `(?:^|[\s;&|(]|\\n)`) before it, and bounds what follows with `(?:[^"\\;&|]|\\[^nrt])*` so it cannot run into a later command.

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

**A command can be put on the Bash tool's `PATH` through the shell that starts the run.** The run inherits the shell's `PATH` (the eval docs list it among the variables that reach the child), the `env` field only accepts `EVAL_*` names, and a scaffold cannot change `PATH` for the run. Probed on 2.1.319: a directory prepended to `PATH` before `claude plugin eval` was first on the Bash tool's `PATH`, was readable inside the sandbox, and a script in it wrote a log file into the workspace. `od_prepare_env` prepends `tools/evals/bin`, which holds a stand-in `gh` that appends each call's arguments to `.gh-calls.log` at the workspace root and answers like the real one (`pr create` prints a URL, `pr checks` exits 0, `run list` prints JSON, `pr merge --auto` is refused as on a repository without required checks). Cases grade the log with `{ source: file, path: .gh-calls.log }`. Running `claude plugin eval` by hand without `od_prepare_env` leaves the real `gh` (or none) first, so those graders fail; use `run-suite.sh` or `pressure.sh`.

The hook probe used a temporary hook in the throwaway copy; the plugin's own hooks (`SessionStart`, `PreToolUse`, `Stop`) run in every with-arm run.

**Shell commands in a Bash-granted run cannot write to the workspace or to `TMPDIR`.** A probe on 2026-11-07 (Linux, WSL2) found the run's working directory, its home and the `TMPDIR` it sets read-only to Bash, while `/tmp` was writable; the Edit and Write tools still write the workspace. `overdrive risk` therefore falls back from `TMPDIR` to `/tmp` (and then to the repository's run directory) before it gives up and reports critical.

## Risk classifier

The deterministic risk classifier (`overdrive risk`, [risk-map.md](risk-map.md)) is measured against labeled corpora in `tests/risk/corpus/`. Labels follow the written policy in `tests/risk/corpus/LABELING.md`, are frozen by `SHA256SUMS`, and change only in a deliberate relabel commit with a reason line.

- **Synthetic** (`synthetic/<case>/`): one small authored repository per rule and per counterexample, classified in `--worktree` mode. CI runs it on every push (job `corpus` in `ci.yml`).
- **OSS** (`oss.tsv`): 64 commits of `vercel/next.js`, `trpc/trpc`, `better-auth/better-auth` and `medusajs/medusa`, labeled blind from the policy and each commit's patch. It needs the network, so it runs nightly (`corpus.yml`) on blobless clones cached under a key derived from `oss.tsv`.

```
bash tests/risk/run-corpus.sh --synthetic tests/risk/corpus/synthetic
bash tests/risk/run-corpus.sh --tsv tests/risk/corpus/oss.tsv --clone-cache DIR [--map FILE]
```

`--map FILE` classifies every row with that risk map instead of the project's, to try a project's rules on its history before committing them.

The gate is `under = 0` (no change classified below its label), `critical_recall = 1.00` (every critical change classified critical) and `over_rate ≤ 0.25` (changes classified above their label, over all changes labeled below critical).

| Corpus | Date | Commit | Rows | under | critical_recall | over | over_rate | Gate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Synthetic | 2026-11-07 | `9db9831` | 159 | 0 | 1.00 | 0 | 0.00 | met |
| OSS | 2026-11-07 | `9db9831` | 64 | 0 | 1.00 | 2 | 0.11 | met |

The OSS rows a change of the coverage rules could affect (those that change at least one source file and one test file, or delete or rename a test file) were labeled again from the written policy by a labeler who never saw the classifier. Two OSS rows come out above their label:

- `trpc` `f08ba07`: `money` from the camelCase word `subscription` in `httpSubscriptionLink.test.ts`, where the project uses the word for streaming subscriptions.
- `better-auth` `639b20f`: `untested-change` for `packages/i18n/src/index.ts`. The package tests it in `i18n.test.ts`, which is not named after `index`.

### Known limits

Some floors are only visible to someone who reads what the code means. Labelers mark those items `judgment:`; no path, line or name in the change carries them, so the classifier does not raise them. The generic rules tried on the corpora (any `session` identifier for `auth`, any removed `export` for `public-contract`) also fired on prose, payment sessions and internal modules, including a change labeled direct:

| Row | Item | What only judgment sees |
| --- | --- | --- |
| `vercel/next.js` `a61dab2` | `public-contract` | a public config key moves under `experimental` |

The row still comes out critical through `untested-change`, but the named item is missing.

Test-file conventions the classifier does not read yet, so changes there may be over- or under-counted until a later release:

- A test commented out with a block comment: only lines that start with `//`, `/*`, `*`, `#` or `<!--` are comments, so a case inside `/* … */` whose line starts otherwise still counts as a case.
- `test.fixme(`, `it.todo(` and similar markers are not skips; adding one does not count as removing a case.
- SwiftPM's `Tests/<Target>Tests/` mirrors `Sources/<Target>/` by target name, not by path, so a test there does not cover its source unless they share a directory.
- .NET test projects (`*.Tests/`) mirror the product project by name, likewise; files there that are not named `*Test(s).cs` are not tests.
- Kotest specs (`*Spec.kt`) are not recognized as tests. Two rules cover such cases. The model may raise a lane, never lower it: when the change plainly touches a floor that no signal names, the model adds the item. A project names its own exported surface, session code and secret helpers in `.overdrive/risk-map.conf` (`symbol`, `path`, `keyword` rules), so the classifier catches them from then on.

## Release results

Full tier, pinned models (`claude-sonnet-5-5`, `claude-opus-5-5` as main), Claude Code 2.1.322, run on 2026-11-10 (UTC; some reruns continued after midnight). Each skill's `RESULTS.md` holds the sonnet run. The pressure column counts scenarios (slash-invoked and `-natural` entries) whose runs were judged compliant in at least 80% of the runs, 5 runs each, with-skill arm only; main ran the `-natural` scenarios only. Cost is the full tier only. "—" means the run was not made (cost ceiling) or is not comparable (partial).

| Skill | Model | Suite score (cases passed) | Trigger train / validation | Pressure | Full-tier cost |
| --- | --- | --- | --- | --- | --- |
| compound-learning | sonnet | 0.99 (24/25) | 15/15, 5/5 | 2/4 | $11.91 |
| compound-learning | main | 0.99 (21/22, partial at the cost ceiling) | 11/13, 4/4 (2 errored) | 1/2 | $26.77 |
| decision-log | sonnet | 0.92 (21/24) | 10/10, 8/10 (below the 90% floor) | 3/6 | $10.97 |
| decision-log | main | 0.97 (22/24) | 10/10, 10/10 | 1/3 | $25.28 |
| decision-planning | sonnet | 1.00 (26/26) | 11/11, 9/9 | 6/6 | $11.93 |
| decision-planning | main | 1.00 (26/26) | 11/11, 9/9 | 2/3 | $27.64 |
| deep-research | sonnet | 0.99 (16/17) | 7/7, 3/3 | 2/2 | $19.00 |
| deep-research | main | — (partial at the cost ceiling) | — | — | — |
| evidence-based-verification | sonnet | 0.98 (22/24) | 10/10, 10/10 | 6/6 | $9.63 |
| evidence-based-verification | main | 0.99 (23/24) | 10/10, 10/10 | 3/3 | $20.81 |
| intent-discovery | sonnet | 0.99 (23/24) | 13/13, 7/7 | 3/6 | $9.40 |
| intent-discovery | main | — | — | 0/3 | — |
| parallel-execution | sonnet | 0.99 (23/24) | 12/12, 8/8 | 1/2 | $13.70 |
| parallel-execution | main | — | — | 0/1 | — |
| release-gates | sonnet | 1.00 (6/6) | no trigger cases | 0/1 | $3.76 |
| release-gates | main | 1.00 (6/6) | no trigger cases | — | $8.35 |
| risk-scaled-execution | sonnet | 0.99 (25/26) | 14/14, 6/6 | 0/3 | $18.97 |
| risk-scaled-execution | main | — (partial at the cost ceiling) | — | — | — |
| risk-scaled-review | sonnet | 0.98 (24/25) | 9/9, 11/11 | 4/4 | $13.53 |
| risk-scaled-review | main | 0.97 (23/25) | 9/9, 11/11 | 2/2 | $27.87 |
| risk-triage | sonnet | 0.97 (30/32) | 14/15, 10/10 | 3/3 | $14.68 |
| risk-triage | main | — | — | — | — |
| root-cause-debugging | sonnet | 1.00 (23/24) | 15/15, 5/5 | 4/4 | $10.75 |
| root-cause-debugging | main | 1.00 (24/24, 6 errored runs) | 12/15, 5/5 | 2/2 | $30.95 |
| skill-evaluation | sonnet | 0.90 (4/5) | no trigger cases | 0/2 (2 errored runs) | $7.56 |
| skill-evaluation | main | — | — | — | — |
| test-driven-development | sonnet | 0.93 (21/24) | 12/14, 6/6 | 4/6 | $12.25 |
| test-driven-development | main | 0.61 (14/24, 13 errored runs at the 15-turn cap) | 6/14, 4/6 | 3/3 | $36.35 |

End-to-end suite (sonnet, 3 runs per case, $11.70): 5 of 7 cases at 1.00; `e2e-critical-after-approval` 0.90 and `e2e-looping-builder-stops` 0.92.

These numbers meet the release thresholds only partly; the failures that remain are cases below 0.9, trigger misses, and pressure scenarios under 4 of 5. Errored runs are not evidence and are listed as such. The main-model column is incomplete on purpose: the cost ceiling for the suite stopped the remaining main runs.
