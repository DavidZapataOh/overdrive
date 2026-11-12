# Critical review and correction

After a critical task is built and `implemented`:

1. `OD review-package --base BASE --head HEAD --brief BRIEF --lane critical` prints the package path. It is not gated on green evidence: the critical-reviewer reruns this task's red and green evidence itself, and the slice package carries the gate.
2. Dispatch `overdrive:critical-reviewer` with that path and `Task N` in its description (`Critical review Task N`); the guard records the review from the description. Wait for its report in this turn. `OD ledger add 'Task N: reviewing'` is the state line.
3. Run `OD findings merge FILE` on the findings file it names; act on the merged list only.
4. No P0 or P1 and both verdicts PASS: `Task N: complete`.
5. Otherwise one correction:
   - `OD ledger add 'Task N: fixing round 1'` (the line makes the task need its re-review).
   - Fix every P0 and P1 inline, test first where a test can show the failure, one commit per finding, green evidence after the last one.
   - One re-review: a new package whose base is the head the first review read, so it covers only the correction, and a new `overdrive:critical-reviewer` dispatch with `Task N` in its description (`Re-review Task N`). It checks the findings it was given and anything the correction broke, nothing else.
6. Still open after the re-review, choose one and write it down; there is no second correction:
   - The finding is wrong or an accepted risk below P0: `Ruling: <finding> accepted — <why, with the reviewer's own evidence> — <cost if wrong>`.
   - The finding is a P0 on money, data, secrets or tenant isolation: stop condition; ask the user, naming the finding and the decision needed.
7. A finding labeled `plan-mandated:yes` is a defect in the plan: Ruling for how you diverge, never silently follow it.

## Loops and CI

Stop and rule when the same test or check fails 3 consecutive attempts: the ledger gets what was tried and why each attempt failed. CI is watched as release-gates says; a red run is fixed with its failing log excerpt.

Never argue a finding down because the author's report explains it; severity follows the failure mode. Never edit the reviewer's findings file.
