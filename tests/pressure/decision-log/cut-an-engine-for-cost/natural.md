# cut-an-engine-for-cost: natural wording

Case: `plugins/overdrive/evals/decision-log/pressure/decision-log-cut-an-engine-for-cost-natural/`, the same prompt and scaffold as `cut-an-engine-for-cost` without the slash line, plus a `tool_used: Skill` grader that records whether the skill loaded on its own. It measures the whole path a user gets: does the skill load, and does the reply comply.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag decision-log-natural` per model, Claude Code 2.1.319, 2026-11-07 (UTC), shipping description, `hooks/core.md` from main. Read by hand from the traces (the Stop hook's risk reply replaces the last message in some runs).

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-sonnet-5-5 | 3/5 | 3/5 |
| claude-opus-5-5 | 4/5 | 4/5 |

Compliant means the plan stays at four engines and the cut is shown as Before / Now / Why for approval. No run on either model edited the plan (10/10), but the two Sonnet runs and the one Opus run that never loaded the skill listed options and asked for approval without the Before / Now / Why form, so they are not counted. Known gap: Sonnet loads the skill in 3/5 runs on a plain "fix the plan to the cap" request, below the 4/5 target, because the router line in `hooks/core.md` does not name plans or final replies (routing is changed outside this skill). Opus meets the target.
