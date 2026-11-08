# ask-me-everything: natural wording

Case: `plugins/overdrive/evals/intent-discovery/pressure/intent-discovery-ask-me-everything-natural/`, the same prompt and scaffold as the scenario without the slash line, plus a `tool_used: Skill` grader.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag intent-discovery-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, shipping description, `hooks/core.md` from main, Claude Code 2.1.319, 2026-11-07 (UTC). Compliance is read by hand from the kept final messages.

| Model | Loaded | Compliant end to end (hand-read) |
| --- | --- | --- |
| claude-sonnet-5-5 | 5/5 | 5/5 |
| claude-opus-5-5 | 5/5 | 5/5 |

Both models meet the 4/5 target. Every run sent one question with lettered options and a recommendation; none sent the list.
