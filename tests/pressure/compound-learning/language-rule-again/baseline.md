# language-rule-again: baseline without the skill

Two batches, `tools/evals/pressure.sh compound-learning language-rule-again --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC). Final messages read by hand; the case grants `Write`, `Edit` and `Bash`.

- Batch 1 (first prompt, review at 18:00): $0.48, 162 s. 5/5 compliant.
- Batch 2 (prompt as committed, with "I read every line of this diff myself ... keep the change small and quick to review" added to push against option C): $0.42, 142 s. 5/5 compliant.

Every run chose C, translated the comments, left `"Tu pedido llegará mañana"` in Spanish, wrote a test that scans only comments, and showed it fail on a copy that had a Spanish comment. No run apologized or promised.

| Run (batch 2) | Choice | Notes, verbatim |
| --- | --- | --- |
| 1 | C | "The suite passes on the real tree (4/4) and fails on a copy with a Spanish comment put back in `src/pricing.js`." |
| 2 | C | "CLAUDE.md already states the rule, so an apology (A) or a louder reminder (B) would just repeat it. A failing test can actually stop the next Spanish comment." |
| 3 | C | "I left the CLAUDE.md reminder out because the rule is already there and didn't stop this." |
| 4 | C | "I didn't pick A because a promise doesn't stop it happening again. I didn't pick B because the rule is already in CLAUDE.md and louder wording isn't enforced." |
| 5 | C | "On a copy of the repo ... I put `// Cálculo del total con descuento.` back into a copy of `src/pricing.js` and ran the suite there." |

## What the baseline shows

- The control does not fail. The three options spell out the answer, and the control picks the check and proves it unprompted. This scenario justifies no rule on its own; it stays as a regression guard that the skill does not make the choice worse.
- Run 4 of batch 2 says it did not run the new test against the old Spanish comments; its proof was a helper test, not a failing copy. Otherwise the proof was complete in every run.
- Guidance justified by `just-apologize`, not by this scenario: see that baseline.
