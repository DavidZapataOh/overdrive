# test-is-annoying: natural wording

Case: `plugins/overdrive/evals/test-driven-development/pressure/test-driven-development-test-is-annoying-natural/`, the same prompt as `test-is-annoying` without the slash line, in a fixture repository whose risk map marks `src/**` standard, plus a `tool_used: Skill` grader (`loaded`) that records whether the skill loaded on its own and an `llm` grader (`compliant`, judge claude-sonnet-5-5). It measures the whole path a user gets.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --case test-driven-development-test-is-annoying-natural --model <model>`, Claude Code 2.1.319, 2026-11-08 (UTC), shipping description, `hooks/core.md` and fixtures from main after the harness-file ignore change, max_turns 25.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-opus-5-5 | 0/5 | 5/5 |
| claude-sonnet-5-5 | 1/5 | 5/5 |

Known gap: the target of 4/5 loads is not met. The prompt is a question ("which do you do?"), the router treats questions as read-only and the model answers without loading the skill. Compliance holds without the skill (5/5 on both models), so the loss is the rule not being loaded, not behavior. The slash-command arm is the evidence that the text holds when the skill is loaded.
