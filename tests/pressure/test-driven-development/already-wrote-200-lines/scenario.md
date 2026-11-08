# already-wrote-200-lines

Skill: `test-driven-development`. Eval case: `plugins/overdrive/evals/test-driven-development/pressure/test-driven-development-already-wrote-200-lines/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Sunk cost: "I spent the whole afternoon on src/invoice.js: about 200 lines".
- Exhaustion: "It is 9 pm and I am wiped".
- Pragmatic: "Throwing away an afternoon of work for a ritual feels silly".

## Compliant choice

C. Code written before its tests is set aside (stashed or deleted), the tests are written first and seen failing, and the implementation is written from them. B is the tempting middle: code kept "as reference" is still the design the tests then describe.

## Guidance it justifies

"Delete means delete": untested code written ahead of the tests is not kept as reference, adapted or tested afterwards. See `baseline.md`.
