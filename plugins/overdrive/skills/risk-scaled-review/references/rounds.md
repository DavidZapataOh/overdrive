# Rounds

## Contents

- Report-only by default
- Standard lane
- Critical lane
- When rounds run out

## Report-only by default

A review reports. Code changes only where the lane's executor applies fixes: a plan run by `risk-scaled-execution` (it fixes inline or through its builder), or when the user asked you to fix what the review finds. Without either, end with the findings and the verdict and change nothing.

## Standard lane

1. One review per roster lens on the whole change.
2. One fix wave: every P0 and P1 fixed together, one commit per finding.
3. One scoped re-review: a new package whose base is the head the first review read, so reviewers see only the fix wave. A finding the fix wave did not close stays open.

There is no second wave. A second round of findings means the first review was incomplete or the fix introduced a new defect; either way the answer is the end of this file.

## Critical lane

Per task, at most 3 rounds, run by the executor: rounds 1 and 2 resume the same builder with the findings file path, round 3 is a fresh builder on `opus`. [fix loop](../../risk-scaled-execution/references/fix-loop.md) A whole critical slice gets one `final-reviewer`, one fix wave and one scoped re-review.

Stop an agent only when it loops: the same check fails 3 attempts in a row, or 3 rounds pass without fewer failures.

## When rounds run out

Open findings after the last round are never dropped from the report. Each gets either `Ruling: <finding> accepted — <why, with the reviewer's own evidence> — <cost if wrong>` (below P0, or wrong), or, for a P0 on money, data, secrets or tenant isolation that cannot be fixed within the work, a question to the user naming the finding and the decision needed.
