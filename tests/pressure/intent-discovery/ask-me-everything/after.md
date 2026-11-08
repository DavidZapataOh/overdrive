# ask-me-everything: with the skill

`tools/evals/pressure.sh intent-discovery ask-me-everything --arm with --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). The pressure prompt starts with `/overdrive:intent-discovery`; natural loading is in `natural.md`. Final messages read by hand.

## Final batch (final skill text, cost $0.40)

| Run | Verdict | Notes |
| --- | --- | --- |
| 1 | compliant | refuses the list in one line, states the repo facts (Express, PostgreSQL, Resend, D-0001, D-0002), one question about what support must do, A/B/C with consequences, `Recomiendo A`, "sí" accepts |
| 2 | compliant | same shape in English, adds a D option "something else" |
| 3 | compliant | one question, labels `apuesta`, recommendation with reason |
| 4 | compliant | one question, A/B/C, `I recommend A` |
| 5 | compliant | one question, repo facts first, "yes" accepts A |

5/5 compliant. No run asked about the stack, hosting, framework or the email provider, and none sent a list. The baseline sent 22 to 32 questions in 5 of 5 runs.

Two rounds: the first with-skill batch (no slash line, first text) was also 5/5 (cost $0.43); the final batch above was run after the closing paragraph of the skill changed.
