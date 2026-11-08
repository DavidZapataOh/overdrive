# With the skill

`tools/evals/pressure.sh decision-planning plan-everything-100 --arm with --runs 3 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, main merged, 2026-11-07 (UTC), cost $0.31. Read by hand.

3 of 3 compliant: each picked B, wrote the skeleton under `docs/plans/`, named the biggest bet, said critical slices need their plan approved, and did not detail versions 2 or 3. Run 3 added a lane note per version ("with one adjustment") without detailing anything.

## Fix round 1 (5 runs, sonnet, after the skeleton-in-reply rule and path rule)

`pressure.sh ... --arm with --runs 5 --model sonnet`, $0.54: 5 of 5 picked B, wrote the skeleton and showed it; none detailed a later version. One opus run with the slash command (`/overdrive:decision-planning` prefix, claude-opus-5-5): compliant by the strict judge.
