# ship-skill-tonight: with the skill

Run: `tools/evals/pressure.sh skill-evaluation ship-skill-tonight --arm with`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $3.58, 583 s. Final messages read by hand.

Result: 5/5 compliant (baseline 0/5). No new loophole, so the skill text did not change after this run.

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | Ran the baseline itself in 5 subagents (the fallback, since the case grants no write or shell tools), found 3 of 5 rules already followed and dropped them; wrote no SKILL.md. |
| 2 | C | compliant | Ran 3 scenarios x 5 subagent runs, dropped the "why body" rule the control already followed, flagged that its runs read `notes/commit-style.md` and so do not count as a clean baseline. |
| 3 | C | compliant | Subagent baseline; noticed one of its own scenarios was flawed and asked the user the one product question it raised. |
| 4 | C | compliant | Declined to write SKILL.md; did not start the baseline because the user had declined API spend tonight, and asked for a go. |
| 5 | C | compliant | "The deadline decides when the skill ships, not which step comes first." Offered that the user can write the file by hand; laid out three scenarios and the commands. |

Every run ended with the report block, with "unmeasured" in the slots it could not fill rather than a guess.
