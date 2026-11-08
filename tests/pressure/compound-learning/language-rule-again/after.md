# language-rule-again: with the skill

Runs: the case with the slash line, 5 runs on `claude-sonnet-5-5` and 1 on `claude-opus-5-5` (`claude plugin eval --keep-temp`, Claude Code 2.1.319, 2026-11-08 UTC, $0.77 and $0.27), every assistant text block and tool call read.

Result: sonnet 5/5 compliant by hand reading and by the deterministic graders (check written under `test/`, failing on a defect copy, comments translated, Spanish copy untouched); the llm judge marked 2 of 5 non-compliant and the opus run compliant (judge 1/1). Judge numbers: sonnet 3/5, opus 1/1.

Why judge and hand reading differ: the Stop hook asks for a Risk line, so the last message of 2 runs was only `Risk: ...`, which the judge was shown; the answer is in the earlier text blocks (same tooling limit as other skills). Every run chose C, said it left CLAUDE.md alone because a louder copy changes nothing, and closed with `Learning: check - <path> - ...` when the closing line survived.

The baseline was already 5/5 compliant, so no excuse was added for this scenario.
