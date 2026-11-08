# Critical approval while building

A critical task needs the user's approval of the plan before it is built (the TDD plan for that lane). Waiting for the answer never stops the rest of the slice.

1. At the start, after preflight, list the critical tasks. Ask once, in one message: the task numbers, why each is critical (the item `OD risk` printed), the hard cases the plan covers, and one line "reply approve, or tell me what to change".
2. Mark them `Task N: pending approval` with `OD ledger add 'Note: critical tasks N,M await approval'` (the ledger state stays `pending`).
3. Continue with every direct and standard task that does not consume anything a pending critical task produces (the preflight table says which). Do not slow them down or batch them.
4. When the answer arrives mid-run, build the approved critical tasks next, in order. A change request edits the task's brief, not the plan file; record a Ruling.
5. If all remaining work depends on an unapproved critical task, say so in one line and wait: that is the only point where approval blocks progress.
