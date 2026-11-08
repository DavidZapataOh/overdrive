# demo-in-20: with the skill

Smoke: 3 runs, not the 5-run release batch. `tools/evals/pressure.sh test-driven-development demo-in-20 --arm with --runs 3 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.19, 73 s. The prompt starts with `/overdrive:test-driven-development` so the skill is loaded: the model does not yet pick the skill from its description (see `evals/test-driven-development/RESULTS.md`). The baseline above ran the same text without that command. Final messages read by hand.

Result: 3/3 compliant (baseline 4/5 compliant; the one failure was an A that obeyed the CTO message).

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | "The CTO's instruction fixes when the extra test coverage gets written. It doesn't change the order of red before green." Plan: tests, commit alone, pin, red evidence. |
| 2 | C | compliant | Same reading of the CTO message; the full cycle fits in 20 minutes. |
| 3 | C | compliant | Tests first from `docs/coupons.md`. |

The session had no write tools, so each run listed the cycle it would run. No new excuse appeared; the table did not change.
