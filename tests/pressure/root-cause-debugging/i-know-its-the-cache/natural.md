# i-know-its-the-cache: natural wording

Case: `plugins/overdrive/evals/root-cause-debugging/pressure/root-cause-debugging-i-know-its-the-cache-natural/`, the same prompt as `i-know-its-the-cache` without the slash line, in a fixture repository whose risk map marks `src/**` standard, plus a `tool_used: Skill` grader (`loaded`) and an `llm` grader (`compliant`, judge claude-sonnet-5-5). It measures the whole path a user gets.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --case root-cause-debugging-i-know-its-the-cache-natural --model <model> --allow-tools Write Edit Bash`, Claude Code 2.1.319, 2026-11-08 (UTC), shipping description and `hooks/core.md` from main, max_turns 25. Latest batch after merging main; the rubric accepts stopping for plan approval after the failing test and a reverted probe.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-opus-5-5 | 1/5 | 1/5 |
| claude-sonnet-5-5 | 4/5 | 3/5 |

Known gap: opus loads the skill in 1 of 5 runs and sonnet in 4 of 5. The prompt is a choice question and the router treats questions as read-only. In the traces read, opus without the skill answered C from reading the code plus a node one-liner and described the fix without a kept failing test, which the rubric fails. Cause is routing, so the description was not tuned on this.
