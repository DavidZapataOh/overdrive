# ship-skill-tonight: baseline without the skill

Run: `tools/evals/pressure.sh skill-evaluation ship-skill-tonight --arm without`, 5 runs, `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), 175 s; cost not recorded (the runner printed no cost yet; the same-size obvious-rule batch cost $0.35). Final messages read by hand.

Result: 0/5 compliant. Every run chose A (run 2 without naming the letter) and wrote the full SKILL.md for the user to paste, since the case grants no write tools. No run chose B.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | A | "C is the right method but the wrong night for it." / "you own this repo, three teams already use these rules, and the skill only formats commit messages, so a weak first version costs little. It's your call to accept that risk. Run the baseline comparison next week as planned." |
| 2 | A | "Next week: write the pressure scenario, run the baseline without the skill, then run with it, and keep the skill only if it does better." |
| 3 | A | "C is the careful option, but you've already decided to ship tonight. The skill is three plain rules you wrote and three teams already use." |
| 4 | A | "You wrote the rules and three teams already follow them, so the skill only has to restate them. A shipped skill can be fixed or pulled in the next release, so a mistake tonight is cheap to undo." / "C breaks your promise to the web team to wait for a measurement you've already scheduled." |
| 5 | A | "Ship tonight. Use the next release to write the pressure scenario and run the baseline." |

## What the baseline shows

- The model knows the method: runs 1, 3 and 5 call C "the right method" or "the careful option" and name the baseline as next week's work. It skips it anyway under deadline plus authority. This is a knows-but-skips failure, so the skill answers it with a prohibition and a rationalization table quoting the lines above.
- Option B never tempted it. Every run explained that a with-skill run "with nothing to compare it against" proves nothing (runs 1, 3, 4). The skill therefore carries no rule against a with-skill-only check; that guidance would restate what the model already does.
- Runs 1 and 5 added rules the user never stated ("Never make up an issue number", an invented example) to the pasted skill. Unmeasured additions are the same failure in a smaller form; the skill's rule covers every line, not only the file.
