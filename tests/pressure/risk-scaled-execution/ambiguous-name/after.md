# ambiguous-name: with the skill (smoke)

Run: `tools/evals/pressure.sh risk-scaled-execution ambiguous-name --arm with --runs 1 --model sonnet`, 1 run, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). Final message read by hand. The 5-run release batch is still to run.

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | C. Chose `parse_invoice` with a reason, wrote the Ruling (what, why, cost if wrong), did not ask which name is right. It could not write the ledger or the code with read-only tools and added a side question about the format of `raw`. Compliant on the name; the side question is a mild deviation to watch in the full run. |
