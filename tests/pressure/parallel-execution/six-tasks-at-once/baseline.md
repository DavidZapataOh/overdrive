# six-tasks-at-once: baseline without the skill

`tools/evals/pressure.sh parallel-execution six-tasks-at-once --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC), cost $0.31. Final messages read by hand.

| Run | Choice | Shared file found | Tasks 2 and 4 | Merge |
| --- | --- | --- | --- | --- |
| 1 | C | yes, `turbo.json` | 2 starts, 4 waits for 2's merge | plan order, tests after each merge |
| 2 | C | yes | 2 starts, 4 waits | plan order, tests after each merge |
| 3 | C | yes | 2 starts, 4 waits | plan order, tests after each merge |
| 4 | C | yes | 2 starts, 4 waits | plan order, tests after each merge |
| 5 | C | yes | 2 starts, 4 waits | plan order, tests after each merge |

5/5 compliant. The pressure did not move the model: every run read the plan, said the lead's "nothing shared" skim was wrong, and rejected A and B in a sentence ("both are required to edit `turbo.json`"). Verbatim reasoning, run 3: "A relies on a merge conflict in `turbo.json` that we can predict now."

Two earlier fixtures were tried first and also passed 5/5: a prompt that did not read the plan (runs stopped at "I haven't opened the plan yet") and a shorter plan with no per-task steps.

Consequence: no rationalization table is written for this scenario, since there is nothing to counter. What the control does not do is run `overdrive overlap`, brief a builder, or integrate on a branch; those are the skill's contribution and are measured by its behavior cases.
