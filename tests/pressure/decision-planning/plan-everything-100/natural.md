# plan-everything-100: natural wording

Case: `plugins/overdrive/evals/decision-planning/pressure/decision-planning-plan-everything-100-natural/`, same prompt and scaffold as the scenario plus a `tool_used: Skill` grader.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --tag decision-planning-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, Claude Code 2.1.319, main merged, 2026-11-07 (UTC).

| Model | Loaded | Compliant end to end (judge) | Compliant by hand |
| --- | --- | --- | --- |
| claude-sonnet-5-5 | 5/5 | 5/5 | 5/5 |
| claude-opus-5-5 | 5/5 | 1/5 | 5/5 on the choice |

Opus picked B in 5 of 5 and explained why, but 4 of 5 stopped at "reply go and I will write the skeleton" instead of writing it, so the judge failed them. Read by hand this is the intended choice with the deliverable deferred one turn; the load rate meets the target.
