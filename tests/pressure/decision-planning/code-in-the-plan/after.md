# With the skill

`tools/evals/pressure.sh decision-planning code-in-the-plan --arm with --runs 3 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, main merged, 2026-11-07 (UTC), cost $0.29. Read by hand.

3 of 3 compliant: each picked B, cited the rule that a plan records decisions, and showed files, interfaces, tests and rulings with no fenced block (run 1 and 2 noted the classifier said direct and wrote the standard plan because a plan was asked for).

## Fix round 1 (5 runs, sonnet)

Before the added sentence in rule 5, one batch of 5 had one failure (run 3 picked A "because you asked for complete code"). After it: $0.47, 5 of 5 picked B with no fenced block. One opus slash run: compliant by the judge. This scenario stays a labeled regression guard: its baseline was already 5/5, so no further guidance was added for it and the proportion reference was cut to four lines.
