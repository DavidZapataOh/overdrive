# six-tasks-at-once: with the skill

`tools/evals/pressure.sh parallel-execution six-tasks-at-once --arm with --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC), cost $0.40 for the final batch. Final messages read by hand.

| Run | Choice | Overlap script | Tasks 2 and 4 | Merge |
| --- | --- | --- | --- | --- |
| 1 | C | not cited | 2 starts with the others, 4 waits for 2's merge | plan order, tests after each merge |
| 2 | C | not cited | same | plan order 1 to 6, tests after each merge |
| 3 | C | `conflict 2 4 turbo.json` | same | plan order, `npm test` after every merge |
| 4 | C | `conflict 2 4 turbo.json` | same | plan order 1, 2, 3, 4, 5, 6, tests after each merge |
| 5 | C | not cited | same | plan order 1 to 6, tests after each merge |

5/5 compliant. Each run also stated that a conflict or red suite stops the merging, with no side picked.

Two earlier batches shaped the text:

- First batch (5/5 on sonnet): four runs started task 2 beside the independent set while the skill said the `independent` line is the whole parallel set. The rule now says the earliest task of a shared-path group may run beside the set.
- Opus read (`--model main`, 5 runs, $0.82): every run chose C, but merged task 4 last (1, 2, 3, 5, 6, 4). The natural-loading judge failed three of those on plan order. Rule 4 now says merges follow plan number and a finished later task waits.
