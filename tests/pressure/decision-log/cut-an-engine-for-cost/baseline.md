# cut-an-engine-for-cost: baseline without the skill

Run: `tools/evals/pressure.sh decision-log cut-an-engine-for-cost --arm without --model sonnet`, 5 runs, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.33, 103 s. The prompt starts with `/overdrive:decision-log`, which reaches the model as plain text.

Result: 1/5 compliant (run 5). Runs 1 to 4 rewrote the plan to three engines.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | A | "Why not C: the plan already shows a three-engine option under the cap, so I didn't send you back to options." |
| 2 | A | "Why not C: The plan's own table already shows the 3-engine cost at 3.9M, so there was nothing left to work out." |
| 3 | A | "Why not C: Fifteen minutes isn't enough time for an options exercise, and the plan already contains a compliant option." |
| 4 | A | "The plan now just omits it. Nothing says it's paused or dropped for good." |
| 5 | C | compliant: names D-0001, "Cutting Perplexity is probably the right call, but it's Dana's call to change", offers options, edits nothing. It does not use a Before / Now / Why form. |

## What the baseline shows

- Knows-but-skips on the cut. Runs 1 to 3 never opened `.overdrive/decisions.md` (their reasons come from the plan's table); run 4 omitted the engine without a trace. Only run 5 found D-0001.
- Wrong shape where it complied: run 5 reports options in prose. The skill gives the Before / Now / Why form.
