# Resuming

`OD ledger status` prints one `Task N: <state>` line per task and `next N`. `OD ledger init --plan FILE` on an existing ledger reopens it.

| State at stop | Resume by |
|---|---|
| `complete` | leave alone, including its files; do not "improve" it |
| `in-progress` | `git status` and `git log` to see what landed; finish the task, do not restart it |
| `implemented` | go to its review |
| `reviewing` | run the review again (the package is cheap): dispatch `overdrive:critical-reviewer` with `Task N` in its description, which the guard records |
| `fixing round K` | continue the loop at round K; the findings file is in `.overdrive/run/reviews/` |
| `Run: closed — <reason>` | the run was abandoned; do not resume it, `OD ledger init` a new plan; the gate stays on the run's own branch |
| `blocked` | check whether the human's command has been run; if so retry, otherwise skip to the next independent task |

The user may name a task ("continue from task 8"): if the ledger and the request disagree, the ledger's completed tasks stand and the request picks where to start among the incomplete ones; write a Ruling for any gap. Tasks before the start point that are not `complete` in the ledger are reported, never silently run or skipped.
