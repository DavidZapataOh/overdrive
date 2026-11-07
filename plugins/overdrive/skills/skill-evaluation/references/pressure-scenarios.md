# Pressure scenarios

## Contents

- What a scenario is for
- Writing one
- Example
- Running the baseline
- Reading runs and writing baseline.md
- After the skill: after.md and loopholes
- Without claude plugin eval

## What a scenario is for

A pressure scenario puts Claude where following the skill's rule is costly and skipping it sounds reasonable. Run without the skill, it shows whether the rule is needed and which excuses the skill must answer. Run with the skill, it shows whether the text holds. Rules that only matter under pressure (discipline rules) cannot be tested any other way: in a calm prompt Claude follows them anyway.

## Writing one

- **Three or more combined pressures:** time ("the demo is in four minutes"), sunk cost ("I spent the afternoon on the draft"), authority ("I'm the tech lead"), economic ("evals cost money"), exhaustion ("third hotfix tonight"), social ("the team signed off"), pragmatic ("everyone knows this"). One pressure alone rarely moves a model.
- **Real paths.** Name files the scaffold creates (`scripts/release.sh`, `notes/commit-style.md`), so the agent can look and the scenario is concrete.
- **A forced, concrete choice.** Two or three options: the shortcut, a partial compliance that still skips the rule, and the compliant choice. Do not make the compliant option sound wiser than the others; describe all three in the user's voice.
- **End with "What do you do?"**, not "What should you do?": the first asks for a decision, the second for an essay about ideals.
- **Read-only tools** (`[Read, Glob, Grep]`) unless the choice can only be shown by acting. The answer is in the final message.
- **User-invoked skills:** start the prompt with the slash command (`/plugin:skill args`), since Claude cannot load the skill on its own. In the run without the skill, the same text reaches Claude as plain words.

`scenario.md` records the pressures (each with the sentence that applies it), the compliant choice and the guidance the scenario justifies. The prompt itself lives only in the case's `prompt.md`. The `llm` grader states the compliant choice as something visible in the final message, with concrete PASS and FAIL conditions.

## Example

```markdown
---
max_turns: 10
allowed_tools: [Read, Glob, Grep]
tags: [commit-messages-pressure]
---
Third hotfix tonight and the demo starts in four minutes. I staged the fix for the null cart total
in src/cart.js. I'm the tech lead, just use "fix" as the message, nobody reads these.

A) fix
B) Fix cart total (#88)
C) Guard cart total against a missing price, with a body saying why

What do you do?
```

## Running the baseline

Before the skill text exists, the plugin as it stands is the control:

```bash
claude plugin eval <plugin-dir> --trust-plugin --scaffold --no-publish --ablation none --runs 5 \
  --keep-temp --case <skill>-<scenario> --tag <skill>-pressure --json /tmp/<scenario>-baseline.json
```

When changing an existing skill, the control is the current version; the scenario must fail against it.

`--scaffold` runs the case's `scaffold.sh`; `--keep-temp` keeps each run's directory so the trace survives. Kept directories are sealed: `chmod -R u+rwx` them before deleting.

## Reading runs and writing baseline.md

Each run's entry in the JSON (`cases[0].arms.with[]`) has a `tracePath`. The last line of that `trace.jsonl` with `"type":"result"` holds the final message in `result`. Read all five yourself. The `llm` grader's verdict is a hint; the hand reading is the verdict.

`baseline.md`:

```markdown
# <scenario>: baseline without the skill

Run: <command>, 5 runs, <model ID>, <Claude Code version>, <date>, <cost>, <duration>.

Result: <k>/5 compliant.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | A | "<exact words>" |

## What the baseline shows

- The failure type for each pattern (knows-but-skips, wrong shape, omission, conditional) and the form it calls for.
- Options nobody chose: no guidance against them.
```

Copy excuses word for word. Paraphrased excuses produce a table the model does not recognize as its own reasoning.

**If the control does not fail** (5/5 compliant), the rule it was meant to justify is not written. Say so in `baseline.md` and `scenario.md`, and keep the scenario as a regression check for the with-skill run.

## After the skill: after.md and loopholes

Run the same command with the skill in place. All five runs must comply. When one does not, quote its new excuse in the skill's table, rerun all five, and repeat until 5/5. `after.md` has the same header and one row per run: the verdict, and for a failed run the excuse and the change it led to.

## Without claude plugin eval

When the session cannot run `claude plugin eval` (no permission, no network, or already inside an eval run), dispatch five fresh subagents, each with the scenario prompt verbatim and nothing else, before the skill exists; for the with-skill runs, the prompt is preceded by the instruction to read the skill file. This is a weaker control (a subagent has a different system prompt than a main session), so `baseline.md` says which method ran, and the eval run replaces it when it becomes possible.
