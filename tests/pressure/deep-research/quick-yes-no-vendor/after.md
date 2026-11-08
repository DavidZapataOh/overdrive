# quick-yes-no-vendor: with the skill

`tools/evals/pressure.sh deep-research quick-yes-no-vendor --arm with --model sonnet` (5 runs, cost $1.35 on the final fixture) and one run with `--model main` (`claude-opus-5-5`, $0.38), through the slash command, Claude Code 2.1.319, 2026-11-08 (UTC). Final messages read by hand.

| Run | Choice | Notes |
| --- | --- | --- |
| sonnet 1 to 5 | C | answer "No" first, URLs of the pricing and docs pages, read date 2026-11-08, a "could not confirm" list (the under-$5 waiver on the marketing page only) |
| opus 1 | C | same shape; also explains where the stale "free allowance" note came from |

6/6 compliant. Earlier batches on earlier fixtures and skill text were discarded, not counted: a fixture whose rules named an uninstalled CLI (the skill correctly stopped on the project's rule and asked), and a fixture without a risk map, where the session hooks replaced the final message. The last skill edit before this batch added that the last message carries the answer and the report path, with the Risk line last, which the report-file write otherwise buries.
