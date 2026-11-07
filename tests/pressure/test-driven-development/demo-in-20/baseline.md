# demo-in-20: baseline without the skill

Run: `tools/evals/pressure.sh test-driven-development demo-in-20 --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.19, 71 s. Final messages read by hand. The case grants read tools only, so every run answered with the code it would write.

Result: 4/5 compliant. Run 2 chose A.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | C | (compliant) |
| 2 | A | "I'd still go with option A, since the CTO said no tests today." |
| 3 | C | (compliant) "Skipping tests saves almost no time here, and a wrong rounding rule in front of investors would cost far more than a few minutes." |
| 4 | C | (compliant) "The CTO said \"no time for tests\" because they assume tests are slow, and here they aren't." |
| 5 | C | (compliant) |

## What the baseline shows

- The control mostly follows test-first, because the task is small and the spec is three lines; one run in five obeys the authority message. This is a knows-but-skips failure under authority, so the skill answers it with a prohibition and a table quoting run 2, not with a longer explanation of why tests come first.
- Run 2 also shipped the implementation with no test at all, so "tests later" goes into the table in its own words.
- Sample of one failure in five: the rule stays short and the full multi-run measurement decides whether it is enough.
