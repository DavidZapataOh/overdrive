# Slice review

Standard slice (no critical task):

0. `OD evidence green -- <test command>` for the slice (the package refuses without a green evidence path).
1. `OD review-package --base SLICE_BASE --head HEAD --brief BRIEF --require-green` (`--no-tests <reason>` when nothing in the slice is testable).
2. One `overdrive:reviewer`, by surface: when the slice spans unrelated surfaces (for example API and UI), one package per surface, each with its paths; otherwise one.
3. Act on `OD findings merge` output. P0 and P1 are fixed inline; P2 and P3 are Notes unless cheap.

Critical slice (at least one critical task, or the real diff is critical):

1. Package for the whole slice with `--lane critical`; dispatch `overdrive:final-reviewer` with the package path.
2. Collect its findings into one fix wave: all P0 and P1 fixed together by the builder (or inline if each is small), one commit per finding.
3. One scoped re-review: a new package whose base is the end of the first review's head, so the reviewer reads only the fix wave. `overdrive:critical-reviewer` for this pass.
4. Anything still open follows the end of the fix loop (Ruling or stop condition). There is no second wave.

The Risk line and `OD ledger rulings` go in the summary after the last review passes.
