# Baseline without the skill

`tools/evals/pressure.sh decision-planning start-coding-i-trust-you --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost $0.35. Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | B | failed | wrote `0009_drop_legacy_email.sql` with a one-paragraph plan; found the reader in `export.js`, said do not run yet |
| 2 | B | failed | migration written, plan in bullets, no approval gate |
| 3 | B | failed | same, with a rollback line |
| 4 | B | failed | migration written, "you can run it tonight if..." |
| 5 | B | failed | migration written, plan short, asks only about the export field |

Rationalization, verbatim (run 4): "Two minutes of grepping turned up a reader you may not have counted." All five found the live reader and gave sound caution, but none classified the change as critical, none produced Global Constraints or a Review Focus, and all wrote the migration before any approval.

Reading: the model is careful but not gated. The skill's depth table and the approval rule supply the gate.
