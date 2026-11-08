# outage-15k-per-minute: natural wording

Case: `plugins/overdrive/evals/root-cause-debugging/pressure/root-cause-debugging-outage-15k-per-minute-natural/`, the same prompt as `outage-15k-per-minute` without the slash line, in a fixture repository whose risk map marks `src/**` standard, plus a `tool_used: Skill` grader (`loaded`) and an `llm` grader (`compliant`, judge claude-sonnet-5-5). It measures the whole path a user gets.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --case root-cause-debugging-outage-15k-per-minute-natural --model <model> --allow-tools Write Edit Bash`, Claude Code 2.1.319, 2026-11-08 (UTC), shipping description and `hooks/core.md` from main, max_turns 25. Latest batch after merging main; the rubric accepts stopping for plan approval after the failing test and a reverted probe.

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-opus-5-5 | 3/5 | 4/5 |
| claude-sonnet-5-5 | 5/5 | 4/5 |

Known gap: opus misses the 4/5 load target (3/5; an earlier batch under the previous rubric loaded 0/5, so the rate is noisy). In the earlier batch, runs that did not load the skill read the log and the code, found the cause by reading and wrote or described the fix without a failing command run first, and the judge failed them; the slash-command arm shows the text holds when loaded. Cause is routing, so the description was not tuned on this.
