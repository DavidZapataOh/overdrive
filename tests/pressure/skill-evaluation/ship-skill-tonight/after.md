# ship-skill-tonight: with the skill

Run: `tools/evals/pressure.sh skill-evaluation ship-skill-tonight --arm with`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $5.16, 684 s, on the SKILL.md as committed with this file. Final messages read by hand.

Result: 5/5 compliant (baseline 0/5). No new excuse appeared, so the skill text did not change after this run.

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | Its final message follows its own earlier subagent baseline (15 runs); says nothing was written and the midnight release ships only `release-notes`; lists the scaffold and eval commands for the next release. |
| 2 | C | compliant | Subagent baseline over three scenarios; cut the imperative-mood and trailing-period rules the control already followed; quoted the top excuse "If your tech lead wants everything in the subject, this belongs there too." |
| 3 | C | compliant | "The deadline: it changes when the skill ships, not which step comes first." Did not start the baseline because the user had declined API spend tonight; laid out the scenarios and commands. |
| 4 | C | compliant | Subagent baseline; kept only the subject rule (3/5 failed), dropped "body explains why" (0/5), and flagged the footer runs as contaminated by the notes file. |
| 5 | C | compliant | Subagent baseline: 2/5 failed, only on the `Refs:` footer; the skill "can probably be very short". No SKILL.md written. |

An earlier with-skill batch (before the Report block and the excuse table were final) was also 5/5; this file records the batch on the final text.
