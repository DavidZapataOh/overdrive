# Integration

After every builder in the parallel set has reported. `BASE` is the branch the slice started from; `OD` is `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`.

1. Read each report's first line. A builder with `BLOCKED` or `NEEDS_CONTEXT`, or with no commit, is not merged: ledger `Task N: blocked <reason>` and treat it like a conflict (rule 5).
2. The Agent result names each worktree's branch. Do not merge from a worktree path.
3. In the main checkout: `git switch -c integrate-<plan-stem> BASE` and leave it checked out when you finish.
4. For each remaining task, in plan order:
   - `git merge --no-ff -m '<the task commit subject>' <branch>`
   - the full suite, with the exact command the user or the plan names or `package.json` defines (`node --test`, `npm test`), never a path-scoped run such as `node --test packages/x/`
   - green: `OD ledger add 'Task N: implemented'`
5. Conflict: `git merge --abort`, then the ledger Note from rule 5. Red suite after a clean merge: `git revert -m 1 --no-edit HEAD`. Either way the task and every later one go back to sequential execution on this branch, one at a time, each starting from the green tip.
6. When all are merged or serialized and the suite is green: `git worktree remove <path>` for each builder worktree, `git branch -d` the merged builder branches, then the closing report (rule 6) and the slice review.
   - `git worktree remove` refuses a dirty worktree: do not pass `--force`. Keep that worktree and its branch and run `OD ledger add 'Note: kept <path> — uncommitted changes'`.
   - A builder branch that was not merged (blocked, conflicted, red) stays: `git branch -d` would refuse it, and its commits are what the serialized rerun reads. Name it in the closing report as `not merged` and leave deleting it to the user.

Notes

- Builders cannot see each other's work; that is why the set is chosen by the script. A merge conflict in a set the script called independent is a defect in the plan's Files lists: ledger a `Note:` with the path.
- Push the integration branch once, after the last green merge. The controller session watches its CI in the background and sends a fix with the failing log; builders are never re-dispatched to wait on it.
