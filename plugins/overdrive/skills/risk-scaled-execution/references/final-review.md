# Slice review

Both kinds start the same way: `OD evidence green -- <test command>` after the slice's last commit. The slice package refuses (exit 65) without green evidence at that HEAD; `--no-tests <reason>` states why nothing in the slice is testable.

Standard slice (no critical task):

1. `OD review-package --base SLICE_BASE --head HEAD --brief BRIEF --require-green`.
2. One `overdrive:reviewer`, by surface: when the slice spans unrelated surfaces (for example API and UI), one package per surface, each with its paths; otherwise one.
3. Act on `OD findings merge` output. P0 and P1 are fixed inline; P2 and P3 are Notes unless cheap.

Critical slice with one critical task: that task's critical review, with its correction and re-review, is the slice review. Build the slice package with `--lane critical --require-green` to confirm green evidence and that no critical task is unreviewed, then deliver.

Critical slice with two or more critical tasks:

1. Package for the whole slice with `--lane critical --require-green`; dispatch `overdrive:final-reviewer` with the package path, `model: opus` when any task's items include money, data-migration, tenant-isolation or secrets. It is refused (exit 65) while a task marked critical has had no `overdrive:critical-reviewer` dispatch (with `Task N` in its description) since its last `in-progress`, `implemented` or `fixing round` line: run that task's critical review first.
2. Fix all its P0 and P1 findings inline in one wave, one commit per finding.
3. One scoped re-review: a new package whose base is the head the final review read, so the reviewer reads only the fix wave. `overdrive:critical-reviewer` for this pass.
4. Anything still open follows step 6 of the correction (Ruling or stop condition). There is no second wave.

The Risk line and `OD ledger rulings` go in the summary after the last review passes.
