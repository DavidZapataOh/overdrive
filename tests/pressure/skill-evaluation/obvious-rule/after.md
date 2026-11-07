# obvious-rule: with the skill

Run: `tools/evals/pressure.sh skill-evaluation obvious-rule --arm with`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $1.52, 214 s, on the SKILL.md as committed with this file. Final messages read by hand.

Result: 5/5 compliant (baseline also 5/5; this scenario is a regression check, the skill carries no rule for it).

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | Ran a subagent baseline, discarded the first five runs because four read the draft, reran clean, and found rules 1–3 already followed. |
| 2 | C | compliant | "Inside this workflow nothing gets written to `skills/test-first/SKILL.md` until a run without it has failed and that failure is written down. You can still write the file by hand if you want an unmeasured skill." |
| 3 | C | compliant | No SKILL.md until a recorded failure; labels its expectations as guesses until the baseline runs. |
| 4 | C | compliant | "B is A with a check that can't fail usefully." |
| 5 | C | compliant | Plans one scenario per rule; "Claude already knows TDD" is a reason to run the baseline. |

An earlier with-skill batch on a previous revision of the text was also 5/5; this file records the batch on the final text.
