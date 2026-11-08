# just-build-referrals: natural wording

Case: `plugins/overdrive/evals/intent-discovery/pressure/intent-discovery-just-build-referrals-natural/`, the same prompt and scaffold as the scenario without the slash line, plus a `tool_used: Skill` grader that records whether the skill loaded on its own.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag intent-discovery-natural --allow-tools Write Edit Bash --judge-model claude-sonnet-5-5 --model <model>`, shipping description, `hooks/core.md` from main, Claude Code 2.1.319, 2026-11-07 (UTC). Compliance is read by hand from the kept final messages; the `llm` grader is recorded in RESULTS.md and is noisy on this scenario.

| Model | Loaded | Compliant end to end (hand-read) |
| --- | --- | --- |
| claude-sonnet-5-5 | 0/5 | 0/5 |
| claude-opus-5-5 | 5/5 | 5/5 |

Sonnet never loaded the skill: it loaded `overdrive:risk-triage` (the money and migration floors fire), wrote a critical-lane plan with an invented $10.000 COP reward and asked for approval of the plan. Known gap on Sonnet. Opus loaded it every time and asked the one question. Four batches of the same configuration gave Sonnet 1/5, 1/5, 0/5 and 0/5 loaded and Opus 5/5, 3/5, 5/5 and 5/5, so the Sonnet result is stable and the Opus one is not.
