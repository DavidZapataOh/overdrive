# Fix loop (critical tasks)

After a critical task is `implemented`:

1. `OD review-package --base BASE --head HEAD --brief BRIEF --lane critical` prints the package path. It is not gated on green evidence: the critical-reviewer reruns this task's red and green evidence itself, and the slice package carries the gate. Dispatch `overdrive:critical-reviewer` with that path and `Task N` in its description (`Critical review Task N`): the guard records the review from the description. `OD ledger add 'Task N: reviewing'` is the state line.
2. Read its report. Run `OD findings merge FILE` on the findings file it names; act on the merged list only.
3. No P0 or P1 and both verdicts PASS: `Task N: complete`.
4. Otherwise `OD ledger add 'Task N: fixing round K'` and:
   - Round 1 and 2: resume the same builder (SendMessage to its id) with the findings file path, not the findings text. It fixes, commits, and reports. Build a new package for the new head and re-review. Every fix needs a new `overdrive:critical-reviewer` dispatch with `Task N` in its description (for example `Re-review Task N fix`): the guard records it, and without it the final review and the PR are refused.
   - Round 3: a fresh `overdrive:builder` with `model: opus`, given the brief path and the findings file path.
5. Findings still open after round 3: choose one and write it down.
   - The finding is wrong or accepted risk below P0: `Ruling: <finding> accepted — <why, with the reviewer's own evidence> — <cost if wrong>`.
   - The finding is P0 on money, data, secrets or tenant isolation and cannot be fixed within the plan: stop condition; ask the user, naming the finding and the decision needed.
6. A finding labeled `plan-mandated:yes` is a defect in the plan: Ruling for how you diverge, never silently follow it.

## Loops and CI

Progress is the only limit; there is no turn cap. Stop an agent only when it loops: the same test or check fails 3 consecutive attempts, or 3 fix rounds pass without the failing count dropping. The stopped builder's report lists every attempt, why each failed and the current state. Continue with a fresh builder briefed from that report plus the committed code; if that one loops too, it is a ledgered ruling or a stop condition (step 5).

Builders push and hand back; they never wait for or poll CI. The controller watches CI in the background and dispatches a fix with the failing log excerpt.

Never argue a finding down because the author's report explains it; severity follows the failure mode. Never edit the reviewer's findings file.
