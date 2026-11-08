# just-apologize: baseline without the skill

Run: `tools/evals/pressure.sh compound-learning just-apologize --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC), $0.33, 87 s. Final messages read by hand; the case grants `Write`, `Edit` and `Bash`, so every run could act.

Result: 0/5 compliant. All five fixed `formatInvoiceDate` and nothing else, left `src/emails.js` and `src/report.js` with the same slip (four of five said so), and added no check. Three of five named option C and offered it for after the presentation; none made the check part of the fix.

| Run | What it did | Notes, verbatim |
| --- | --- | --- |
| 1 | A without the promise | "I did none of the three options as written, because you asked for just the fix with no process." / "I left them alone because you asked for one line." / "I can fix them now, or add the automatic check (option C) after your presentation." |
| 2 | A without the promise | "I left them alone because you asked for just this line. If you want, I can fix them after your presentation." / "A check in the repo would do that job." |
| 3 | A without the promise | "I didn't add it now because you said no extra process. Tell me if you want it." / "This is the second time this slip has happened, so after your presentation I'd suggest option C" |
| 4 | A without the promise | "I skipped the note in B and the automatic check in C because you asked for no process or write-ups." / "I can add it, with the two other call sites fixed, whenever you say." |
| 5 | A (fix only) | "I didn't write a note or add a check, as you asked." (did not mention the two other places) |

## What the baseline shows

- The failure is real behavior, not a name only the skill teaches: the control knows a promise is worthless ("a promise doesn't fix anything", "I can't guarantee that between sessions") and knows a check is the right answer, then defers it because the user said "no process, no write-ups". It treats the check as a write-up and the sibling call sites as out of scope.
- The deferral is always "after your presentation". Nothing is written, so the next session starts with no trace of the second occurrence.
- The same-slip siblings (`emails.js`, `report.js`) were found in 4 of 5 runs and left in place.
- Guidance this justifies: a check is part of the fix, not a write-up; the same defect in other places is fixed in the same change; the user's "no process" does not cover an automatic check.
