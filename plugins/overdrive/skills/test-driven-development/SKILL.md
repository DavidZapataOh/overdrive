---
name: test-driven-development
description: Use when about to edit code so that a function, endpoint or rule behaves differently — a new function, a bug report (wrong output, an input that is rejected or mishandled), a small or one-line fix, a rushed change — in a repo with a runnable test command. Not for debugging a failure, reviewing tests, explaining TDD or setting up a test runner.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Test-driven development

No implementation code before a failing test that was seen failing. A one-line fix, a deadline and an instruction to skip tests do not change that.

`overdrive` is `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`; it is not on the Bash PATH, so call it by that path.

## When it applies

It applies when both hold:

- the change alters behavior: a feature, a changed output, a bug fix;
- the repository has a runnable test command (an npm `test` script, a Makefile `test` target, pytest, `go test`, `cargo test`).

Anything else ends with this line and no tests: `TDD: n/a — <reason>`. Reasons: configuration or formatting only, docs only, a rename with no behavior change, no runnable test command.

## The rule

| Excuse (verbatim from baseline runs) | Reality |
| --- | --- |
| "I'd still go with option A, since the CTO said no tests today." | The instruction decides the schedule, not the order of the steps. A test from the spec takes minutes and is the proof the demo works. |
| "Deleting or stashing 200 working lines is mostly ritual here." | Code written before its tests is the design the tests would then copy. Stash or delete it, write the tests, implement from them. |
| "The ritual isn't what matters here. What matters is watching a test fail for the right reason, and you can do that without deleting the afternoon's work." | A test written against code that already exists passes at once; the only red left is the new rule, and the rest of the code is untested. |
| "Add tests for the rest of the file in the next session." / characterization tests that "should pass right away" | Tests that were never red prove nothing. They are written before the code or not at all. |
| "Deleting the file and re-deriving it costs you hours at 9 pm." | The second version is written against tests and takes a fraction of the first. Time spent on the first is not a reason to keep it. |

Code written before its tests is not kept open as reference, adapted to the tests, covered afterwards, or pasted back from a stash. Move it out of the working tree (`git stash -u`, or delete it) before the first test and do not read it again while implementing.

## The cycle

Run it once per behavior: a small group of tests for one behavior, then its code, then the next behavior. Writing every test first and every implementation after is horizontal slicing and tests imagined behavior.

1. Write the tests through the public interface, the way a caller uses it, from the spec or the request. In the critical lane, list the hard cases first (references/by-lane.md) and cover each one.
2. Commit the tests alone.
3. `${CLAUDE_PLUGIN_ROOT}/bin/overdrive pin <test files>`
4. `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence red -- <test command>`. The failure must be the missing behavior: read it. A syntax error, a missing import or a typo is not red; fix that and run again.
5. Implement the least that passes.
6. In the critical lane, run the non-regression check first ([references/non-regression.md](references/non-regression.md)): the new tests fail on the previous code, the old suite passes on the new code. Then `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence green -- <full test command>`
7. Refactor with the suite green and run green again.
8. `${CLAUDE_PLUGIN_ROOT}/bin/overdrive pin --clear`, then commit the implementation.

Skip the pin only in the direct lane. Evidence is what a reviewer reads; a test run you did not record with `evidence` did not happen.

## A pinned test is not edited

Never edit, weaken, skip or delete a pinned test to get to green; the guard denies the edit anyway. If the test and the spec disagree, the spec wins and the code changes. A test is wrong only when it contradicts the spec or the request, and then: `${CLAUDE_PLUGIN_ROOT}/bin/overdrive pin --release "<reason>"`, fix the test, commit it, pin it and run red again. State the reason in the final message.

## Depth by lane

The lane is the one `overdrive risk` gave for this change; if it was not run, run it before the first test.

| Lane | What the cycle includes |
| --- | --- |
| direct | steps 4 and 6 recorded; pin optional |
| standard | the full cycle |
| critical | the full cycle, a hard-cases list written first, real dependencies you own, and the non-regression check before green |

Details per lane and the hard-cases list: [references/by-lane.md](references/by-lane.md). The non-regression recipe: [references/non-regression.md](references/non-regression.md). What a good test is: [references/test-quality.md](references/test-quality.md).

## Close

End with one line: `TDD: red <evidence file> → green <evidence file>`, or the `TDD: n/a` line above. Include `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence list` output when the lane is critical.
