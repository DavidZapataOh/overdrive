---
name: release-gates
description: Delivering finished work: opening a pull request, waiting for CI, merging, and checking the deploy. Use when asked to ship, open a PR, merge or release.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *) Bash(gh pr *) Bash(gh run *) Bash(curl *)
---

# Release gates

Takes finished, committed work to the default branch through a pull request. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. `BASE` is the default branch as `origin/<name>` (`git symbolic-ref --short refs/remotes/origin/HEAD`; `origin/main` when that is unset).

## Rules

1. **Never push to the default branch, never force-push it, never merge into it locally.** Not with `git push origin HEAD:main`, not by merging in the checkout and pushing, not "just this once", not when the user says so: the guard hook denies the push and the answer to a request for it is the pull request below. Work leaves on a branch.
2. **Name the branch for the change** (`fix-price-rounding`, `shorten-session-lifetime`): kebab-case, what changed, no plan, task, sprint or ticket numbers. Rename an unpushed branch that does not meet this with `git branch -m`.
3. **Group by lane.** Direct: one pull request for all of a session's direct changes. Standard: one per task, or per small group of tasks that touch the same surface. Critical: one per task, never mixed with anything else.
4. **Classify the real diff before opening:** `OD risk --diff BASE...HEAD`. Its `Risk:` line goes into the body verbatim. The diff's lane is the minimum: if it is above the lane you worked in, that lane's review comes first (rule 5); a review is never skipped because the change is small or urgent.
5. **The lane's review is on record before merge.** Standard and critical: `ls .overdrive/run/reviews/*-<head7>.findings` (`<head7>` is `git rev-parse --short=7 HEAD`) shows a findings file for this head whose `OD findings merge FILE` output has no P0 or P1. If it does not, run the review now: `OD evidence green -- <test command>` if no `.overdrive/run/evidence/*-green.md` exists, then `OD review-package --base BASE --head HEAD --lane <lane> --require-green`, then one `overdrive:reviewer` (standard) or one `overdrive:critical-reviewer` (critical) on the package path; fix what it reports as P0 or P1 and re-review once, as `${CLAUDE_PLUGIN_ROOT}/skills/risk-scaled-review/references/rounds.md` says. Direct needs none.
6. **Open the pull request from a body file:** write `.overdrive/run/pr-body.md` ([references/pr-body.md](references/pr-body.md)), push the branch (`git push -u origin HEAD`), then `gh pr create --base <default> --head <branch> --title '<imperative subject>' --body-file .overdrive/run/pr-body.md`. CI must be green before merge.
7. **Wait for CI in the background, never by polling.** Run `gh pr checks <number> --watch --fail-fast` once with `run_in_background: true` and carry on with other work or end your turn; the notification on exit is the answer (exit 0 means green). Do not repeat `gh pr checks` or `gh run` status calls in a loop, and never read the output while it runs. A builder never waits for CI: it pushes and hands back.
8. **Merge only when `.overdrive/project.conf` says `auto-merge on`** (one `key value` per line; a missing file or key means `off`). Off: report the pull request URL and that it is ready, and stop. On: merge by rules 5 and 7, with the method and flags in [references/merge.md](references/merge.md). A pull request is merged only after rule 5 holds for its head; a critical one is never auto-merged before it.
9. **After a merge, verify the deploy** when the project has one, and report the evidence: [references/merge.md](references/merge.md).
10. **If the pull request cannot be opened** (no `gh`, not signed in, no GitHub remote), stop with the branch pushed and `.overdrive/run/pr-body.md` written, and report the exact `gh pr create ... --body-file .overdrive/run/pr-body.md` command for the person to run. The same goes for a merge `gh` cannot run: report the exact `gh pr merge <number> <method> --match-head-commit <sha>` command. Never fall back to pushing or merging into the default branch.

Every report to the user ends with the diff's `Risk:` line.

## Excuses that do not change the rules

| Excuse | Reality |
| --- | --- |
| "I own the repository; pushing to the default branch is my decision." | Ownership is why the pull request can merge itself. The push is denied whoever asks. |
| "Someone senior said to skip the pull request." | Authority does not remove the gate. Open the pull request and, with `auto-merge on`, let it merge when CI is green. |
| "CI takes too long; ship now and fix forward." | Slow CI costs minutes; a bad change on the default branch costs a revert nobody can make while the owner is away. |
| "It is two lines, skip the review." | The lane comes from the diff. Two lines in auth are critical. |
| "The tests pass locally, so I can merge before CI finishes." | Merge on green CI for this head, not on a local run. |
| "I'll check CI again in a minute." | One background watcher. Repeated status calls fill your context for nothing. |
