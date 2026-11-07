# Eval suite

## Contents

- Layout and names
- Trigger set
- Behavior cases
- Graders
- Running and reading results
- Thresholds and what to do when they fail

Reference: https://code.claude.com/docs/en/plugin-evals

## Layout and names

```
<plugin>/evals/<skill>/
  trigger/<skill>-trigger-<slug>/      prompt.md + graders/
  behavior/<skill>-behavior-<slug>/    prompt.md + case.yaml + scaffold.sh + graders/
  pressure/<skill>-<scenario>/         written by new-pressure-case
  RESULTS.md                           the measured numbers
tests/pressure/<skill>/<scenario>/     scenario.md, baseline.md, after.md
```

`--case` matches the case name (the directory name) only, never the path, and `--tag` keeps any case with one of the listed tags. So case names carry the skill (pressure cases are `<skill>-<scenario>`), and every case is tagged with its tier: `<skill>-trigger`, `<skill>-behavior`, `<skill>-pressure`. Tags are a flow list: `tags: [commit-messages-trigger]`. Cases that use only free graders can also carry `<skill>-smoke` for a cheap one-run check.

A case that needs files has a `case.yaml` (`schema_version: "1.1"`, `name` equal to the directory name, `context.scaffold_script: scaffold.sh`) and a scaffold that builds the workspace: a git repository with the files the prompt names. Scaffolds run only with `--scaffold`, in an empty directory, with a 120-second limit. Each run starts from that workspace; nothing from your machine (CLAUDE.md, settings, other plugins) is loaded, so a rule the skill must read goes into the scaffold as an ordinary file.

## Trigger set

Model-invoked skills only. 20 cases:

- **10 should-trigger**, written the way people type: file paths, backstory, typos, short and long, in every language the users write in. Substantive: "read this file" triggers nothing.
- **10 near-miss should-not-trigger**: each shares a keyword with the skill but needs something else. For a commit-message skill: "what did commit a1b2c3d change?", "write release notes since v1.3", "add a commit-msg hook that rejects long subjects". Unrelated prompts ("what's the weather") prove nothing.

Positive grader:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?commit-messages"'
---
```

Negative grader: the same plus `min: 0`, `max: 0` and `arm: both` (otherwise a two-arm run excludes it from the score).

Prompt frontmatter for trigger cases: `max_turns: 5`, `allowed_tools: [Read, Skill]`.

Then tag the split, which is stable per case name (adding a case never moves another):

```bash
${CLAUDE_SKILL_DIR}/scripts/split-trigger-set <plugin>/evals/<skill>/trigger
```

60 % `train`, 40 % `validation`. Description edits are made only for train failures; validation is the number that counts.

A user-invoked skill has no trigger set. It gets one case with a natural request for what the skill does and the negative grader above, to prove Claude does not invoke it through the Skill tool on its own.

## Behavior cases

One case per failure the baselines recorded, phrased as the user would ask. Each case has two graders:

- one on the **result**: the final message, or a produced file read with `target: {source: file, path: ...}`;
- one on the **steps**: `tool_used` or `tool_order` on the calls that show the skill's process.

Prefer free graders. Use at most one `llm` grader per case, on short output, with concrete PASS and FAIL conditions. Grade long output with `regex` over the file instead.

Tools beyond `Read, Glob, Grep, Skill, Agent, AskUserQuestion, TodoWrite` and the task tools are not granted by `allowed_tools`; pass them on the command line (`--allow-tools Write Edit`). Granting `Bash` runs every command in the OS sandbox, which needs `bubblewrap` and `socat` on Linux.

## Graders

| Type | Passes when | Cost |
| --- | --- | --- |
| `regex` (`pattern`, `flags`, `match: not_contains` or `count:N`, `target`) | the JavaScript regex matches the target | free |
| `tool_used` (`tool`, `input_match`, `min`, `max`) | the number of matching calls is within bounds | free |
| `tool_order` (`before`, `after`, each a tool or `{tool, input_match}`) | both happened and the first `before` precedes the first `after` | free |
| `file_exists` (`path`, `exists`) | a file created during the run matches the glob | free |
| `llm` (body is the rubric, `focus`) | a judge votes PASS in 2 of 3 | judge calls |

`target` and `focus` take `last_message` (default), `trace` (JSON lines; quotes appear as `\"`; an `llm` judge sees only the first and last 12 messages), `files` (created paths, not contents) or `{source: file, path: <path>}`. `input_match` sees the JSON-encoded input, so anchor file paths on `"file_path"\s*:\s*"[^"]*..."` rather than a loose `.*` that can match file contents. In a two-arm run, `tool_used: Skill` graders are reported but not scored unless they are the only grader or carry `arm: both`.

## Running and reading results

```bash
# before the skill: the with-arm must fail the behavior cases
claude plugin eval <plugin> --trust-plugin --scaffold --no-publish --runs 3 --ablation with-without \
  --tag <skill>-trigger <skill>-behavior --threshold 0.9 --model <pinned model ID> --judge-model claude-sonnet-5-5 \
  --json results.json

# one case, one run, while writing graders
claude plugin eval <plugin> --trust-plugin --scaffold --no-publish --runs 1 --ablation none --case <case> --tag <skill>-behavior
```

Pin the model with a full ID so a model release is never mistaken for a skill regression. Pin the judge too (`--judge-model claude-sonnet-5-5` or larger): a small judge can mark a correct answer wrong over formatting and flip the sign of a delta. `--concurrency N` (up to 8) runs cases in parallel on one rate limit. `--max-cost-usd` stops the run and marks it partial; never record a partial run.

In the JSON: `cases[].aggregates` has `score`, `scoreWithout` and `delta`; the suite's `aggregates` has `overallScore` and `meanDelta`; each run in `cases[].arms.with[]` and `.without[]` has `score`, `costUsd`, `durationSeconds`, `error` and per-grader verdicts. A run with an `error` is not evidence; rerun it. Write the numbers to `evals/<skill>/RESULTS.md`: date, Claude Code version, model IDs, trigger accuracy for train and validation, and per case the score with and without the skill, the delta and the cost.

## Thresholds and what to do when they fail

| Measure | Release floor | When it fails |
| --- | --- | --- |
| Trigger accuracy, validation split | 90 %, with should-trigger rate above 0.5 and should-not-trigger below 0.5 over 3 runs | Tune the description on train failures, five rounds at most, keep the best validation round |
| Behavior cases, with the skill | 0.9 over 3 runs | Read the failing runs' traces; fix the form of the instruction that failed |
| Mean delta | above 0 | The skill does not help: drop it or rewrite it |
| Any case delta | not below 0 | The skill makes that case worse: fix it before shipping, whatever the mean says |
| Pressure scenarios, with the skill | 5/5 compliant, read by hand | Add the new excuse to the table and rerun |

If a case's `tool_used: Skill` grader passes but its delta is negative, suspect the judge and the rubric before the skill. Before changing the `model:` of a skill or agent, run the suite on both models and keep the change only if the cheaper or newer one is not worse.
