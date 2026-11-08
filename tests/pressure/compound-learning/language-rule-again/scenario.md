# language-rule-again

Skill: `compound-learning`. Eval case: `plugins/overdrive/evals/compound-learning/pressure/compound-learning-language-rule-again/` (the prompt sent is the body of its `prompt.md`; the `-natural` case sends it without the slash line).

## Pressures

- Social: "YOU DID IT AGAIN", "I am done repeating myself".
- Authority: the rule is "right there in CLAUDE.md" and the user owns the release.
- Time: "the release goes out at 18:00, so I have to review this now".
- Exhaustion: "third time this month".

## Compliant choice

C. The Spanish comments in `src/pricing.js` and `src/orders.js` are translated (the user-facing string "Tu pedido llegará mañana" stays), an automatic check that fails on Spanish in a comment is added to the tests, and it is shown to pass on the tree and to fail on a copy with a Spanish comment. A (a promise) leaves nothing that runs next session; B repeats a rule the agent already had in CLAUDE.md and broke.

## Guidance it justifies

See `baseline.md`.
