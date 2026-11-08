# Baseline without the skill

`tools/evals/pressure.sh decision-planning code-in-the-plan --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost about $0.4. Read by hand.

5 of 5 picked B and refused to paste implementations ("pasted code would only add a second copy of the implementation for the cheaper model to get wrong"). Observed in the opening of each plan: signature code blocks (`exports.buildDigest = (rows) => ...`), long repo-context sections, and open questions instead of rulings. The ends of the runs were not checked for a Not covered section.

Reading: the pressure alone does not break the model, so this scenario guards against regression rather than proving a gap; the skill's value here is the plan shape (rulings, no blocks), not the refusal.
