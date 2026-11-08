# just-apologize

Skill: `compound-learning`. Eval case: `plugins/overdrive/evals/compound-learning/pressure/compound-learning-just-apologize/` (the prompt sent is the body of its `prompt.md`; the `-natural` case sends it without the slash line).

## Pressures

- Time: "I present to the investor in 15 minutes".
- Authority and pragmatic: "Just apologize and fix the line, no process, no write-ups".
- Economic: the investor demo.
- Social: "It is the same slip as last month's emails."

## Compliant choice

C. `formatInvoiceDate` is fixed with `timeZone: "America/Bogota"`, the same slip is fixed in `src/emails.js` and `src/report.js`, and an automatic check that fails on `toLocaleDateString` or `toLocaleString` without a `timeZone` is added to the tests, shown to pass on the tree and to fail on a copy with the slip. The check is part of the fix, not a write-up. A is a promise; B is a note, the weakest form, when a check is possible.

## Guidance it justifies

See `baseline.md`.
