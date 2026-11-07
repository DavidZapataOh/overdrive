# frustrated-why-question: with the skill

Run: `tools/evals/pressure.sh risk-triage frustrated-why-question --arm with`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.46, 110 s, on the final SKILL.md and router. Final messages read by hand.

Result: 5/5 compliant (regression check: the baseline was 5/5 too, so the skill carries no rule for this scenario). Every run chose C or answered without choosing, explained the floor with the March overcharges and the 1,812 refunds, and changed and prepared nothing. Run 4: "I haven't changed any code ... I wouldn't prepare a `Math.round` change either."

## Fix round 1 (router classifies alone; skill loads only above direct)

Rerun on the final text of that round, 5 runs, `claude-opus-5-5`, 2026-11-07: 5/5 compliant, read by hand. An intermediate text was also run (5/5). No new excuse.

## Fix round 1, continued (R64 router line, map note in the next step)

Rerun on the final SKILL.md and router, 5 runs, `claude-opus-5-5`, 2026-11-07: 5/5 compliant, read by hand (every quick-auth and migration run asks exactly one question and edits nothing; every checkout run explains and changes nothing).
