---
name: skill-evaluation
description: Writing a new Claude Code skill or changing an existing one, with evidence that it changes behavior. Use when creating a skill, editing a skill's body or description, deciding whether a skill earns its place, or when someone asks whether a skill improves results.
disable-model-invocation: true
argument-hint: [skill-name]
allowed-tools: Bash(claude plugin eval *) Bash(claude plugin validate *) Bash(${CLAUDE_SKILL_DIR}/scripts/new-pressure-case *) Bash(${CLAUDE_SKILL_DIR}/scripts/split-trigger-set *)
---

# Skill evaluation

Build `$ARGUMENTS` test first: watch Claude fail without the skill, write the least text that fixes what failed, then measure the difference. `${CLAUDE_SKILL_DIR}` below is the directory of this file.

## The rules

1. **No SKILL.md before a recorded baseline.** Do not create a SKILL.md, or edit one, until a run without that text has failed and the failure is written down: `baseline.md` for a pressure scenario, or a failing eval case for a behavior change. Before every Write or Edit of a SKILL.md, check that this record exists for the change. If it does not, the next action is the baseline, whoever already knows what the skill should say and whatever the deadline.
2. **Every line answers a recorded failure.** A rule the baseline already follows is cut. A skill, or a rule, whose delta is zero or negative is dropped or rewritten, never shipped.

Someone who wants an unmeasured skill can still write the file by hand; inside this workflow, nothing is written before the baseline. Say so plainly, then start the baseline: five runs of a read-only scenario take minutes and cost cents to a few dollars, which is also the answer to "it takes too long".

| Excuse (verbatim from baseline runs) | Reality |
| --- | --- |
| "C is the right method but the wrong night for it." / "you've already decided to ship tonight" | The deadline changes when the skill ships, not the order of the steps. Start the baseline now; ship in the next release. |
| "You wrote the rules and three teams already follow them, so the skill only has to restate them." | People following rules says nothing about what Claude does without them. The baseline shows which rules need text at all. |
| "a weak first version costs little. It's your call to accept that risk." | An unmeasured skill is never pulled: nothing shows it failing. It costs context in every session it loads. |
| "A shipped skill can be fixed or pulled in the next release, so a mistake tonight is cheap to undo." | Same: without a baseline there is nothing that would ever show the mistake. |
| "Ship tonight. Use the next release to write the pressure scenario and run the baseline." | Scenarios written after the text are written to pass it. The scenario and its baseline come first. |
| Adding "just one more" rule or example nobody saw fail | It is unmeasured text. It goes in only with a case that fails without it. |

## Where to start

Find where `$ARGUMENTS` stands and resume from the first missing piece. Work through every step without stopping to ask; stop only for something irreversible, the user's accounts, money or secrets, or a product decision only the user can make.

| Present | Next step |
| --- | --- |
| nothing | 1. Pressure scenarios |
| `tests/pressure/<skill>/*/scenario.md`, no `baseline.md` | 2. Baseline |
| `baseline.md` for every scenario, no eval cases | 3. Eval suite |
| eval cases, no SKILL.md (or a change not yet made) | 4. Write the skill |
| SKILL.md, no `after.md` | 5. Pressure again |
| `after.md` for every scenario, no current `RESULTS.md` | 6. Measure |

If the repository has its own eval scripts or conventions (for example `tools/evals/` or a `docs/evaluation.md`), use them for the runs below; they wrap the same commands.

Before step 1, check that a skill is the right tool: a project convention belongs in CLAUDE.md, anything a script or regex can check belongs in a script or hook, and a one-off needs nothing.

## 1. Pressure scenarios

One scenario per rule the skill will enforce. Scaffold each:

```bash
${CLAUDE_SKILL_DIR}/scripts/new-pressure-case <skill> <scenario>
```

It writes `tests/pressure/<skill>/<scenario>/scenario.md` and the eval case `evals/<skill>/pressure/<scenario>/` (prompt, `llm` grader, scaffold). Fill them in: three or more combined pressures, real paths that the scaffold creates, concrete options to choose from, ending "What do you do?". A user-invoked skill's scenario starts with its slash command. Details and examples: [references/pressure-scenarios.md](references/pressure-scenarios.md).

## 2. Baseline (red)

Run each scenario five times before the skill text exists:

```bash
claude plugin eval <plugin-dir> --trust-plugin --scaffold --no-publish --ablation none --runs 5 \
  --keep-temp --case <scenario> --json /tmp/<scenario>-baseline.json
```

Read every run's final message (the last `"type":"result"` line of each run's `trace.jsonl`, listed as `tracePath` in the JSON) and write `baseline.md`: per run, the choice made and every rationalization copied verbatim. When `claude plugin eval` cannot run in this session, run the scenario prompt in five fresh subagents with nothing else in their prompt, and note that in `baseline.md`.

If the control does not fail, the rule that scenario was meant to justify does not go in the skill. Record that in `baseline.md` and keep the scenario as a regression check.

## 3. Eval suite (before the skill)

Write the cases that the skill must turn from failing to passing ([references/eval-suite.md](references/eval-suite.md)):

- **Trigger set**, model-invoked skills only: 10 realistic should-trigger prompts and 10 near-miss should-not-trigger prompts that share a keyword with the skill but need something else. Then tag the 60/40 split:

  ```bash
  ${CLAUDE_SKILL_DIR}/scripts/split-trigger-set <plugin-dir>/evals/<skill>/trigger
  ```

  A user-invoked skill (`disable-model-invocation: true`) gets one case instead: a natural request with a `tool_used: Skill` grader for the skill, `min: 0`, `max: 0`, `arm: both`.
- **Behavior cases**, one per failure in the baselines: one grader on the result and one on the steps taken, free graders (`regex`, `tool_used`, `tool_order`, `file_exists`) first, at most one `llm` grader.

Run the suite now. Its with-arm must fail the behavior cases, which proves the graders detect the failure. If the suite cannot run in this session, say so; the without-arm of step 6 then stands in as the red.

## 4. Write the skill (green)

Write the least text that turns the recorded failures into passes, in the form that fits each failure ([references/forms.md](references/forms.md)):

| Failure in the baseline | Form |
| --- | --- |
| Knows the rule, skips it under pressure | Prohibition plus a table of the verbatim excuses |
| Complies, but the output has the wrong shape | A positive recipe or template of what the output is |
| Leaves out a required element | A required slot in the template |
| Right behavior depends on a condition | A condition on something observable |

No nuance clauses ("unless it matters", "where appropriate"). For the description, see [references/descriptions.md](references/descriptions.md). Limits: body under 500 lines and 20,000 bytes; the rules that must survive compaction in the first 5,000 tokens; references one level deep, with a table of contents on any reference over 100 lines.

## 5. Pressure again

Rerun each scenario five times with the skill, the same command as step 2. Read every final message yourself; the `llm` grader is a hint, not the verdict. All five must comply. Each new excuse goes into the table verbatim, then the scenario runs again. Write `after.md` with each run's verdict and the excuse that forced a change, if any.

## 6. Measure

```bash
claude plugin eval <plugin-dir> --trust-plugin --scaffold --no-publish --runs 3 --ablation with-without \
  --threshold 0.9 --model <pinned model ID> --judge-model sonnet --json results.json
```

Release thresholds: trigger accuracy 90 % or more on the validation split (should-trigger rate above 0.5, should-not-trigger rate below 0.5, 3 runs each); behavior cases score 0.9 or more with the skill; mean delta above 0 and no case with a negative delta; every pressure scenario 5/5 compliant. Tune the description only on train failures, at most five rounds, and keep the round with the best validation accuracy. A delta of zero or less means drop or rewrite. Before changing a `model:` in any frontmatter, run the suite on both models and compare.

## 7. Static checks

`claude plugin validate --strict <plugin-dir>`, the size limits above, and the repository's own checks (skill shape, always-loaded description budget) when it has them.

## Report

End with this block, every slot filled; "unmeasured" is a valid value, a guess is not:

```
Skill: <name> (<model-invoked | user-invoked>)
Baseline: <scenario>: <k>/5 failed; top excuse "<verbatim>" | rules dropped because the control passed: <list | none>
Trigger set: <k> should-trigger | <k> should-not-trigger, each with the keyword it shares: <case: keyword, ...> | user-invoked: not-auto-invoked case
After: <scenario>: <k>/5 compliant
Suite: trigger validation <x>% | behavior with-skill <s> | mean delta <d> | cases with delta < 0: <list | none>
Cost and time: <USD per step> | <minutes per step>
Unmeasured: <what did not run here, and the exact command that runs it | nothing>
```
