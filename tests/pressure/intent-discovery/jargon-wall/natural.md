# jargon-wall: natural wording

Case: `plugins/overdrive/evals/intent-discovery/pressure/intent-discovery-jargon-wall-natural/`, the same prompt and scaffold as the scenario without the slash line, plus a `tool_used: Skill` grader.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag intent-discovery-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, shipping description, `hooks/core.md` from main, Claude Code 2.1.319, 2026-11-07 (UTC). Compliance is read by hand from the kept final messages.

| Model | Loaded | Compliant end to end (hand-read) |
| --- | --- | --- |
| claude-sonnet-5-5 | 0/5 | 2/5 |
| claude-opus-5-5 | 0/5 | 4/5 |

Neither model loaded the skill: the prompt is an explanation request ("explícamelo en cristiano") and both answered it directly, which the baseline already does well. Known gap for loading. Without the skill, 3 of 5 Sonnet runs and 1 of 5 Opus runs ended with a question about the shop platform, the country or a payment account, announced or asked next to the one question; the skill's rule 5 is what removes that, and it only applies when the skill loads.
