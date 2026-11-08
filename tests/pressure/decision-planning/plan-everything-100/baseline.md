# Baseline without the skill

`tools/evals/pressure.sh decision-planning plan-everything-100 --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost $1.03 (the first prompt, without the board and "last two assistants" pressure, was a discarded batch of $0.36 where 5 of 5 chose B). Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | A | failed | wrote the full plan for all three versions to `docs/PLAN.md` with assumptions |
| 2 | B | compliant | skeleton in the reply, reasons: later versions would be invented |
| 3 | B | compliant | skeleton, asked for approval |
| 4 | B | compliant | skeleton, asked for approval |
| 5 | A | failed | 24 tasks for version 1, 19 for version 2, full plan written |

Rationalization, verbatim (run 5): "It's long, and I haven't committed it." The pressure of authority plus the board moved 2 of 5 runs to detail every version. Even the B runs gave no cost per month, no proven pattern versus bet split and no "Not covered" section.

Reading: rule 3 (detail only the next slice) holds the line the model drops under pressure; `references/skeleton.md` supplies the missing sections.
