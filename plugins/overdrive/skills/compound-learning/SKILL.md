---
name: compound-learning
description: Use when the user corrects the agent, repeats an instruction or names a slip made before ("otra vez", "remember not to"), or a defect got past review or CI.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Compound learning

A correction changes the next session only if it is written where the next session looks, or if a check enforces it. "I'll remember" is neither: nothing carries over except files and checks. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`.

## Rules

1. **Fix the instance first, and every copy of it.** The correction is also a request: repair what was wrong everywhere the same slip occurs in the tree, not only the place named. A check has to pass on the tree, so the other places are part of the change.
2. **One learning per correction.** State it in one sentence: what was done, what should be done.
3. **Durable bar.** Ask: if this note vanished, would someone reading the code repeat the mistake? If not (a typo, a one-off slip, a taste for one task, something the code or tests already make impossible), write nothing and close with `Learning: none — <why>`.
4. **Look before you write.** Read the CLAUDE.md that governs the files concerned, then `OD recall --any <terms>`. If a rule or note already covers it and was broken anyway, that form was too weak: go up the ladder in rule 5.
5. **Take the cheapest durable form, in this order**: an automatic check, then a rule, then a note. A check is part of the fix, not a write-up: "no process", "no write-ups" and a deadline do not exclude it, and it is written in the same change, never offered for later. What each fits and how to write it: [references/forms.md](references/forms.md).
   - A check counts only after it passes on the tree and fails on a throwaway copy that has the defect. Run them as two separate commands, unfiltered, and read the output. A check that cannot be made to fail is not a check: take the next form and say why.
   - A rule is a CLAUDE.md line or a decision entry (`overdrive:decision-log`).
   - A note is `.overdrive/learnings/<slug>.md`, read back only with `OD recall`.
6. **A defect that got past a lane below critical** also adds a risk-map rule and its note: [references/calibrate-risk-map.md](references/calibrate-risk-map.md).
7. **Scope as stated.** A principle the user states for everything is persisted for everything (user-level CLAUDE.md or memory index), not narrowed to this repository. A rule about this project stays in this project.
8. **Never promise.** Do not write "I'll remember", "won't happen again" or "lo tendré en cuenta". Say what was written and where, or that nothing was.

## Stop rules

- Three attempts to make a check fail on the defect copy without success: report and stop; list each attempt and why it failed, and fall back to a rule.
- Where a principle should live (global or this project) is unclear from the words: write it at the narrower scope and report the question.

## Close

End with `Learning: <check | rule | note> — <path> — <what it prevents>`, or `Learning: none — <why>`.

## Excuses already seen

Each of these was said in a test run.

| Excuse | Reality |
| --- | --- |
| "I did none of the three options as written, because you asked for just the fix with no process." | A check that stops the second occurrence is not process. It is a few lines in the test suite, written now. |
| "I left them alone because you asked for just this line." | The same slip in two other files is the same defect. Fix them in this change; the check cannot pass otherwise. |
| "I can fix them now, or add the automatic check after your presentation." / "Tell me if you want it." | After the deadline nothing is written and the next session starts from nothing. Write it now. |
| "I skipped the note and the check because you asked for no process or write-ups." | The user asked for no document. A check is not a document. |
| "I didn't write a note or add a check, as you asked." | Doing as asked and leaving no trace is how the third occurrence happens. |
| "I didn't promise to do better, because I can't guarantee that between sessions." | Right, and it is why the check is written. Not promising is not the same as writing something. |
