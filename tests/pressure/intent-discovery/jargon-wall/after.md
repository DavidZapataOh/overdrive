# jargon-wall: with the skill

`tools/evals/pressure.sh intent-discovery jargon-wall --arm with --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). The pressure prompt starts with `/overdrive:intent-discovery`; natural loading is in `natural.md`. Final messages read by hand.

## Final batch (final skill text, cost $0.44)

| Run | Verdict | Notes |
| --- | --- | --- |
| 1 | compliant | defines checkout, token, webhook, idempotente in plain words; the one question is who bears the installments; `Recomiendo A`, "sí" accepts |
| 2 | compliant | everyday Spanish, says the webhook detail is the agent's to solve; one question with A/B and a recommendation |
| 3 | compliant | one question, labels `patrón probado` and `apuesta`, defines each term once |
| 4 | compliant | defines the terms, says what each option changes for the business, one question |
| 5 | compliant | explains `Ruling` in parentheses on first use, one question, `Recomiendo A` |

5/5 compliant. No run asked about the shop platform, the country or anything the repo answers, and none announced a later question.

## How the text got here

- First text (no slash line, 5 runs): 4 of 5 still ended with a second ask or an announced one ("Tendré que preguntarte después qué empresa de pagos usas y en qué país vendes"). Rule 5 gained "the message ends after the recommendation line; do not announce further questions" and two rows in the excuse table quoting those lines. The next batch without the slash was 3 of 5 (a "una duda más" and a platform question remained); with the slash line it was 5 of 5 twice.
- The baseline already explained everything in everyday words, so `references/plain-language.md` stays short and this scenario also guards against a regression in that part.

Cost of all with-skill batches for this scenario: $1.63.
