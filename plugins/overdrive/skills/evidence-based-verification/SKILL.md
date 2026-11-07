---
name: evidence-based-verification
description: Fresh evidence behind every claim. Use when asked to confirm, wrap up or close out work, or whether it is done, fixed, working, deployed or ready, before saying so or writing its status, when relaying a subagent's report, and before stating a vendor capability, price or law.
---

# Evidence-based verification

## The rule

**Nothing is called done, fixed, passing, deployed, supported or true until evidence for it was produced in this turn.** That holds for your own work, a subagent's, a teammate's and the user's.

Evidence is one of:

- **A command run in this turn** against the code as it is now, with its output read: exit code, pass and fail counts, the failing names.
- **A file read in this turn** for a claim about what exists: the diff, the code, the test file, an evidence file.
- **A source fetched in this turn** for a fact about the outside world: the vendor's own documentation or pricing page, the official text of a law or regulation. Its URL goes on the line.

Not evidence:

- A run from before the last change to the code it covers, however recent ("passed an hour ago").
- Reading code to judge what it does ("looks fine"). Reading shows what exists, not what it does.
- A report: a subagent's, a teammate's, a commit message, the user's own description ("I fixed it", "cosmetic").
- Memory, and any secondhand note about a third party (a project doc, a blog, a forum answer), whatever its date.

An evidence file written by `overdrive evidence` counts when the HEAD it records is the current HEAD and nothing it covers has changed since; otherwise rerun its command. List them with `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence list`.

When the evidence cannot be produced here (no shell, no network, no access), the claim goes under **Not verified** with what would settle it. It is never rounded up to a claim, and it never appears as a fact in text written for someone else.

## What to check before each claim

| About to say | Produce first |
| --- | --- |
| tests pass, it builds, the bug is fixed | Run the test or build command now, on the current tree, and read the result. For a bug, the test that reproduces it is in the run. |
| done, complete, ready to merge | Each part of the request checked against the diff and the files, plus the test run above. |
| the subagent (or teammate) finished | Read the diff of the commits it names (`git log`, `git diff`), the code it says it wrote, and the evidence files it cites. Repeat only what you checked; its other claims stay "the report says" under Not verified. |
| deployed, works in production | A request to the deployed URL, or the deploy's own status output, from this turn. |
| a vendor supports X, costs Y, a law requires Z | The vendor's or the official source, fetched now. Without it: "not verified", with the source you do have and its date. |
| not found, not public, does not exist | Every place and query you tried, listed. |

## Closing

Every message that closes work (done, fixed, a status, a wrap-up, a ticket note, a PR summary, a line for the team) ends with this block. All three slots are always there; an empty slot says `none`.

```
Verified:
- <claim> — <evidence: command and its result | path:line | URL>
Not verified:
- <claim> — <why not, and what was tried>
Pending:
- <what is left, including docs this change made stale> — <what settles it>
```

- A line sits under Verified only with its evidence from this turn named on the line.
- Text written for someone else (ticket note, status line, message to a teammate) states as fact only what is under Verified. Work that is still Pending is not described as done, not even "assuming it gets done first".
- In that text, a fact about a vendor, a price or a law that is not under Verified carries its source and date ("our 2023-03 notes say …"), or stays out.
- Source-of-truth docs the change makes stale (API docs, README, specs, decision log) are updated in the same step, or listed under Pending.

Worked examples of the block, including the line for a team channel: [references/closing.md](references/closing.md).

## Excuses already seen

Each of these was said, word for word, in a test run.

| Excuse | Reality |
| --- | --- |
| "Marta, rounding work is done." / "Rounding work is done and I approve PR #212." (after "I haven't re-run tests on it") | "Done" is a claim about the code as it is now. Nothing ran on it, so the message says not verified and what to run. |
| "It looks fine, but I haven't seen it tested." / "which looks fine. But that's my reading of it." | The line that "looked fine" was the bug. Reading is not a test run; say what the code says, not that it works. |
| "after that I only simplified `roundToCents` in `src/rounding.js` (one line, cosmetic)" | The user's word about a change is a claim. A change's size is not evidence that it is safe. |
| "builder reports done, 14 tests passing, but I can't find `validateIban` on main yet" | Repeating a report's numbers publishes them. State what you checked; the rest is "the report says", under Not verified. |
| "If the commit is real and on a branch, you can post option B." | A commit existing shows the code exists, not that it passes. The tests run on it first. |
| "Wompi takes Nequi for one-time payments." / "Wompi is still cheaper on cards: 2.65% + COP 700 vs 2.99% + COP 900." (from a note dated 2023-03) | A project note about a vendor is a dated secondhand claim. Say "our 2023-03 notes say", put it under Not verified, and name the vendor page that settles it. |
| Line for the CFO: "Wompi takes cards for recurring charges. Recurring Nequi isn't confirmed yet." (from the same 2023-03 note) | The CFO repeats it as current. Attribute it ("our 2023-03 notes say Wompi recurs on cards only") or leave it out. |
| "Wompi's lower fee is real on cards." followed by "The fee part also rests only on our 2023 table, so drop it if they ask for numbers" | A caveat after the line does not travel with it. A line for someone else carries only what is Verified. |
| "Ticket note (assuming the docs section gets added first): … The API is documented in `docs/api.md`." | Write the note for what is true now. The docs update goes under Pending. |

These words in a claim mean its evidence is missing: "looks fine", "cosmetic", "per the report", "reports done", "assuming". Produce the evidence, or move the claim to Not verified.
