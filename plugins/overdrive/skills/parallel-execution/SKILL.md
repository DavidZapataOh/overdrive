---
name: parallel-execution
description: Running several tasks of a written plan at the same time with separate builder agents in git worktrees, then merging their work: fan out tasks N to M, independent tasks in parallel. Not for parallel code, test runs, CI jobs or research.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *)
---

# Parallel execution

Builds plan tasks that share nothing at the same time, one builder per task in its own worktree, and merges the results in plan order. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. The plan is the one risk-scaled-execution runs (`### Task N:` headings with Files lines); its ledger, lanes and review rules still apply.

## Rules

1. **The script picks the parallel set.** `OD overlap --plan FILE --tasks N,N,...` for every task asked for, before any dispatch. Its `independent` line is the parallel set. Tasks in `conflict` lines (and tasks with a `note`, which list no Files) share a path: say which (`conflict 2 4 turbo.json`). Of the tasks that share a path, only the earliest in plan order may run beside the set; each later one waits until the earlier one is merged and starts from that result. Fewer than two tasks that can run at once: no parallel run, hand the slice back to risk-scaled-execution.
2. **A dependency serializes too.** A task that uses something another task creates (file, function, table, name) runs after its producer. Classify each task first (`OD risk --intent '<title>' --paths <its Files>`); a critical-lane task needs the approved plan as usual and gets its critical review after the merge.
3. **One builder, one worktree, one brief.** For each task in the set: `OD brief --plan FILE --task N` prints the brief path; the Agent call is `subagent_type: overdrive:builder` with `isolation: "worktree"` and a prompt that is that path and nothing else. Put all the calls in one message so they run together. Before them, `OD ledger init --plan FILE` when there is no ledger yet, then `OD ledger add 'Task N: in-progress'` for each. Each worktree has its own `.overdrive/run/` (evidence, pins, the builder's notes): read them there, by their absolute path. Builders hand back without waiting on CI.
4. **Integrate on a branch, in strict plan order, tests after every merge.** Merge one task at a time on an integration branch, by plan number: a finished later task waits for an earlier one that is still running, never goes ahead of it. Run the project's full test suite after each merge. Recipe and commands: [references/integration.md](references/integration.md)
5. **A conflict or a red suite stops the merging.** Undo that merge without touching the files, serialize the rest (the failing task and every later one) through risk-scaled-execution on the integration branch, and ledger it: `OD ledger add 'Note: serialized from Task N — <path or failing test>'`. Never edit conflict markers, never take one side (`-X ours`, `-X theirs`, `checkout --ours`) to make a merge go through.
6. **Report one line per agent when done:** `Task N <Status> (<lane>): <short sha> <subject> — merged | serialized | not merged`. Then continue risk-scaled-execution's slice steps: review by lane, reclassify the real diff, deliver. You watch integration CI in the background; no agent polls it.
