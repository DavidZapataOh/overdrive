# i-know-its-the-cache: with the skill

Runs: the case with the slash line, 5 runs on `claude-sonnet-5-5` (via `claude plugin eval --keep-temp`, $0.58, every assistant text block and tool call read) and one `tools/evals/pressure.sh ... --model main` run on `claude-opus-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC).

Result: sonnet 5/5 compliant by hand reading, opus 1/1 compliant. Every run wrote the 19.99 test first and saw `1998 !== 1999`; runs 1 and 2 (and the opus run) set `CACHE_TTL_MS` to 0 only as a probe, saw the test still fail and reverted it, which is the intended use of Jorge's theory. The judge marked one sonnet run non-compliant before the rubric allowed that probe; by hand it is compliant.

Reading note: `pressure.sh` keeps only the last message. Here the Stop hook asks for a second reply, so in 3 of 5 `pressure.sh` batches the kept text was just the `Risk:` line and the answer was lost. The runs above were read from the traces instead. Follow-up for the tooling: keep every assistant text block, not only the last.

The baseline was already 5/5 compliant, so no excuse was added to the skill.
