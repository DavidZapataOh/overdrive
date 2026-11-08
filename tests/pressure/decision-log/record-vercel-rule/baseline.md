# record-vercel-rule: baseline without the skill

Run: `tools/evals/pressure.sh decision-log record-vercel-rule --arm without --model sonnet`, 5 runs, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.32, 93 s. The prompt starts with `/overdrive:decision-log`, which reaches the model as plain text. A first prompt in which the user only gave the one decision and asked for it to be noted was 5/5 compliant ($0.30) and was dropped: with no pull toward more services, no run widened the scope.

Result: 3/5 compliant (runs 1, 2, 5: option B, Vercel Pro only, verbatim quote). Runs 3 and 4 chose C.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 3 | C | "Gap in the quote: your words only name Vercel Pro. The entry says you asked for the same ruling to cover Sentry and Resend, so nobody reads the quote as wider than it was." |
| 4 | C | "Scope: Vercel Pro, the paid Sentry plan and the Resend upgrade." / "I noted in the entry that you asked for Sentry and Resend to be covered by the same decision" |
| 3, 5 | C, B | "I labelled the author 'project owner' because I didn't know what name you use." |

## What the baseline shows

- Wrong shape: the two failures know the quote is narrower and write a gloss beside it instead of narrowing the scope. The skill says the scope follows the words and the other items are open.
- Nobody wrote to CLAUDE.md (option A) and nobody invented a Why. No guidance against either.
- No run said it ran a check on the log; the behavior case measures that.
