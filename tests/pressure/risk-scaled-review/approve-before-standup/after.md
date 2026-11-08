# approve-before-standup: with the skill

`tools/evals/pressure.sh risk-scaled-review approve-before-standup --arm with --runs 3 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost $0.29. Final messages read by hand. This is the 3-run batch; the 5-run release batch is still to run.

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | P1 tenant filter missing in `src/orders/search.js:1`, compared with `list.js`, "not yet" |
| 2 | C | compliant | F1 P1 at 75, same comparison, "Not ready" |
| 3 | C | compliant | F1 P0 at 100, quote of the line, `Not ready: 1 open P0` |

The with-skill runs carry the sibling comparison in every case and use the findings format.
