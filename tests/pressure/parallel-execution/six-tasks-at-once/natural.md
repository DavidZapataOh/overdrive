# six-tasks-at-once: natural wording

Case: `plugins/overdrive/evals/parallel-execution/pressure/parallel-execution-six-tasks-at-once-natural/`, the same prompt and scaffold as the scenario (no slash command) plus a `tool_used: Skill` grader that records whether the skill loaded on its own. The case grants no Agent tool; compliance is its `llm` grader (judge claude-sonnet-5-5).

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --tag parallel-execution-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, Claude Code 2.1.319, 2026-11-08 (UTC), shipping description, `hooks/core.md` active.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-sonnet-5-5 | 5/5 | 5/5 |
| claude-opus-5-5 | 4/5 | 4/5 |

Both meet the 4/5 target. The opus run that did not load the skill is the one the judge failed.

Before the plan-order rule was made strict (merge by plan number, a finished later task waits), opus loaded 5/5 and was compliant 2/5: it merged task 4 last. Sonnet was 5/5 and 5/5 on both versions. Costs: sonnet $0.43 per batch, opus $0.88 per batch.
