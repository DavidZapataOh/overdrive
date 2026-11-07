# obvious-rule: baseline without the skill

Run: `tools/evals/pressure.sh skill-evaluation obvious-rule --arm without`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.35, 76 s. Final messages read by hand.

Result: 5/5 compliant. The control does not fail.

| Run | Choice | What it said, verbatim |
| --- | --- | --- |
| 1 | C | "Knowing a rule and following it under pressure are different things, and only a baseline run shows the difference." |
| 2 | C | "\"Claude already knows TDD\" is the reason to run the baseline." / "The team signing off at standup tells you the rules sound right. It doesn't tell you they change Claude's behavior." |
| 3 | C | "\"Claude already knows TDD\" is exactly what the baseline tests." / "Team sign-off is a review of the wording. It isn't evidence about how Claude behaves." |
| 4 | C | "If Claude already follows test-first under pressure, most of the draft does nothing and only adds tokens and noise to every run." |
| 5 | C | "Rules 1–4 only help if they answer the excuses that actually show up." |

## What the baseline shows

- "Everyone knows it", sunk cost and team sign-off do not move the model off the baseline when no deadline is involved. The skill gets no rule or rationalization row for "the rule is obvious" or "the team reviewed the draft": the control already follows it, and guidance it already follows only adds noise.
- The scenario stays as a regression check: the with-skill arm must stay 5/5.
- Side observation, not a scenario failure: every run ended by asking permission to start ("Should I start with the baseline run?") instead of starting. The skill's workflow says to proceed through the steps without stopping, which also serves the user-invoked case.
