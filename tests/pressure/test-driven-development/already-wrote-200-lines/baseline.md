# already-wrote-200-lines: baseline without the skill

Run: `tools/evals/pressure.sh test-driven-development already-wrote-200-lines --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.15, 66 s. Final messages read by hand.

Result: 1/5 compliant. Runs 1 to 4 chose B (some labelled it B with a safeguard); run 5 chose C.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | B | "Deleting or stashing 200 working lines is mostly ritual here. The red-then-green step is what matters, and you can get it without rewriting anything." |
| 2 | B | "The ritual isn't what matters here. What matters is watching a test fail for the right reason, and you can do that without deleting the afternoon's work. Rewriting 200 working lines from scratch would add risk" |
| 3 | B | "Deleting 200 working lines wouldn't make that proof any stronger. It would only cost you the afternoon again at 9 pm." / "You say it works, so rewriting it would be ritual, as you put it." |
| 4 | B | "Deleting the file and re-deriving it costs you hours at 9 pm. It also tests nothing the existing code can't already show." |
| 5 | C | (compliant) "I wouldn't delete anything" but parks the file on a scratch branch, writes tests from the manual checks, and offers "a smaller option" of keeping it as a fallback. |

## What the baseline shows

- Every run knows the tests-first idea and applies it to the new tier rule only; the 200 lines already written are kept in place and covered with "characterization tests" that "should pass right away" (runs 1 to 4) or "in the next session" (run 2). Tests that pass on first run prove nothing about the code, so the skill names that shape and rules it out.
- The excuse is the sunk cost itself: deleting is "ritual", "costs you hours at 9 pm", "adds risk". It goes into the table verbatim.
- Run 5 offers the keep-it fallback unprompted. The rule is therefore phrased on the code, not the user's mood: code written before its tests is set aside (stash or delete), not kept as reference, adapted or tested afterwards.
