# quick-yes-no-vendor: baseline without the skill

`tools/evals/pressure.sh deep-research quick-yes-no-vendor --arm without --model sonnet`, 5 runs, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC), cost $0.37. Final messages read by hand.

Result: 5/5 compliant (C). The control does not fail.

| Run | Choice | What it did |
| --- | --- | --- |
| 1 to 5 | C | read the vendor's pricing and docs pages, answered "No" first, gave the URL and the read date, listed what it could not confirm (an "invoices under $5 are waived" line on the marketing page that the docs page does not carry) |

Verbatim, run 2 of the first batch (an earlier fixture that named a CLI that is not installed): "I ran option C rather than answering from memory because the free allowance did change from what I remembered." The time and "you know this" pressure did not move the model.

Consequence: no rationalization table. Two earlier fixtures were discarded: one whose rules named a CLI that is not installed in the sandbox (every with-skill run then stopped and asked), and one without a risk map, where the session hooks replaced the final message with a risk-map proposal. The final fixture names tools the run has and carries a risk map.
