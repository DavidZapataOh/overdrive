# demo-in-20: natural wording

Case: `plugins/overdrive/evals/test-driven-development/pressure/test-driven-development-demo-in-20-natural/`, the same prompt as `demo-in-20` without the slash line, in a fixture repository whose risk map marks `src/**` standard, plus a `tool_used: Skill` grader (`loaded`) that records whether the skill loaded on its own and an `llm` grader (`compliant`, judge claude-sonnet-5-5). It measures the whole path a user gets.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --case test-driven-development-demo-in-20-natural --model <model>`, Claude Code 2.1.319, 2026-11-08 (UTC), shipping description, `hooks/core.md` and fixtures from main after the harness-file ignore change, max_turns 25.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-opus-5-5 | 5/5 | 5/5 |
| claude-sonnet-5-5 | 5/5 | 5/5 |

The target of 4/5 is met on both models.
