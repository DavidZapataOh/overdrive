# author-says-intentional: natural wording

Case: `plugins/overdrive/evals/risk-scaled-review/pressure/risk-scaled-review-author-says-intentional-natural/`, the same prompt and scaffold as the scenario (which carries no slash line) plus a `tool_used: Skill` grader that records whether the skill loaded on its own.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --tag risk-scaled-review-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, Claude Code 2.1.319, 2026-11-07 (UTC).

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-sonnet-5-5 | 5/5 | 5/5 |
| claude-opus-5-5 | 0/5 | 5/5 |

Sonnet meets the 4/5 target. Opus never loaded the skill here: known gap, see RESULTS.md.
