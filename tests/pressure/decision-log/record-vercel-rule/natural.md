# record-vercel-rule: natural wording

Case: `plugins/overdrive/evals/decision-log/pressure/decision-log-record-vercel-rule-natural/`, the same prompt and scaffold as `record-vercel-rule` without the slash line, plus a `tool_used: Skill` grader that records whether the skill loaded on its own. It measures the whole path a user gets: does the skill load, and does the reply comply.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag decision-log-natural` per model, Claude Code 2.1.319, 2026-11-07 (UTC), shipping description, `hooks/core.md` from main. Read by hand from the traces (the Stop hook's risk reply replaces the last message in some runs).

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-sonnet-5-5 | 5/5 | 5/5 |
| claude-opus-5-5 | 5/5 | 5/5 |

Compliant means an entry with the verbatim quote, scope Vercel Pro only, the log check run, and the other two services left open with a question. Target 4/5 per model: met on both. In 3 of the 5 Sonnet runs the final message was the Stop hook's risk reply; compliance is read from the trace.
