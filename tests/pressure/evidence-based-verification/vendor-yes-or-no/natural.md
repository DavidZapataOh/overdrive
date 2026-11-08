# vendor-yes-or-no: natural wording

Case: `plugins/overdrive/evals/evidence-based-verification/pressure/evidence-based-verification-vendor-yes-or-no-natural/`, the same prompt and scaffold as `vendor-yes-or-no` without the slash line, plus a `tool_used: Skill` grader that records whether the skill loaded on its own. It measures the whole path a user gets: does the skill load, and does the reply comply.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --case evidence-based-verification-vendor-yes-or-no-natural --model <model>`, Claude Code 2.1.319, 2026-11-07 (UTC), shipping description, final body, `hooks/core.md` from main (router line that names these replies) active.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-opus-5-5 | 5/5 | 5/5 |
| claude-sonnet-5-5 | 5/5 | 5/5 |

Compliance is the case's `llm` grader (judge claude-sonnet-5-5), plus one reply read by hand.

The target of 4/5 natural loads per model is met. Before the router line reached `core.md`, the same description loaded the skill in 0/5 Opus runs and 0-5/5 Sonnet runs depending on the scenario (see RESULTS.md).
