---
name: risk-scaled-execution
description: Executing a written implementation plan or any slice of it (the next slice, tasks N to M), task by task, in any language. Use when asked to execute, build, continue or resume a plan, including an approved plan to implement in full while the user is away.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *)
---

# Risk-scaled execution

Runs a plan task by task. Process scales with each task's lane; the rules below hold in every lane. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. A plan is an Overdrive plan or any file with one `### Task N:` heading per task and `Create:`, `Modify:`, `Test:` file lines.

## Rules

1. **Ledger first.** Resuming a plan ("continue", "pick it up", a ledger under `.overdrive/run/`) runs `OD ledger status` before you read code or edit anything. Otherwise `OD ledger init --plan FILE`, then `OD ledger status`. Resume at its `next` line: a task the ledger shows `complete` is never reopened, redone or re-edited. Record each state change with `OD ledger add 'Task N: in-progress'` (then `implemented`, `reviewing`, `fixing round K`, `complete`, `blocked <text>`). A critical-lane task is recorded `Task N: in-progress critical` as soon as it is classified: the mark is what makes the ledger hold the final review and the PR until that task has been reviewed after its last change. The review is recorded by the guard when you dispatch `overdrive:critical-reviewer` with `Task N` in its description (for example `Critical review Task 2`); a `reviewing` line you write yourself is only a state and does not count, and the hook's record cannot be added by hand. `OD brief --plan FILE --task N` adds the mark itself when it classifies the task critical. Standard and direct tasks go in-progress, implemented, complete, unmarked, and are `complete` before the slice review. Name the task in every `overdrive:builder` and `overdrive:critical-reviewer` description (`Build Task N`, `Fix round K Task N`, `Critical review Task N`): the guard records each builder dispatch as a change that needs a new review. A run that is abandoned is closed with `OD ledger add 'Run: closed — <reason>'`, which frees other branches; on the run's own branch the gate stays.
2. **Classify every task before touching it.** `OD risk --intent '<task title>' --paths <its Files>`. Lane = max(script, your judgment): raise it for risk the script misses, never lower it. A failed classification is critical.
3. **Run inline; dispatch only for a named reason.** Direct and standard tasks run in this session, whatever their size or file count; about 100 changed lines or fewer is always inline. This never applies to the critical lane: a critical-lane task is always built by an `overdrive:builder`, however small. Dispatch a builder only for: a critical-lane task (isolation), parallel independent tasks (read `${CLAUDE_PLUGIN_ROOT}/skills/parallel-execution/SKILL.md`), or this session's context nearing ~150k tokens. [references/inline-vs-dispatch.md](references/inline-vs-dispatch.md)
4. **Pass paths, never pasted history.** Every dispatch gets a file: the brief from `OD brief --plan FILE --task N`, the package from `OD review-package --base SHA --head SHA --brief BRIEF`. Subagents never dispatch. If `overdrive` is not on PATH, call `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`.
5. **Stop only for four things:** an irreversible action, a destructive action, the user's accounts, money or secrets, or a product decision only the user can make. Everything else: decide, then `OD ledger add 'Ruling: <what> — <why> — <cost if wrong>'` and continue. Do not ask the user which of two readings is right; pick one, rule, go on. Rulings that outlive this plan also go to the decision log (read `${CLAUDE_PLUGIN_ROOT}/skills/decision-log/SKILL.md`).
6. **Blockers.** An environment problem still unsolved after about 10 minutes (missing system package, a command needing sudo, a service that is down) is `BLOCKED <exact command the human must run>`: write it in the ledger (`Task N: blocked <command>`) and in your reply, then continue with every task that does not depend on it. Never run `sudo`, install system packages or change the machine yourself.
7. **Never merge below the diff's lane.** Before any PR, run `OD risk --diff BASE...HEAD` on the real diff. If it is above the plan's lane, run that lane's review first. A review is never skipped for a small, urgent or already-approved change.
8. **No pull request before green evidence, the slice's reviewer and release-gates.** Run `OD evidence green -- <test command>` after the slice's last commit (when nothing is testable, say why with `--no-tests <reason>` in the next step), then build the slice package with `--require-green`: it refuses (exit 65) when no green evidence exists at this HEAD. Standard: one `overdrive:reviewer` on that package; critical: the final-reviewer. Then read `${CLAUDE_PLUGIN_ROOT}/skills/release-gates/SKILL.md` and open the PR from its body file. A PR opened first is the failure this rule exists for.
9. **One progress line per task:** `Task N complete (<lane>): <what changed>`. Nothing longer between tasks.

## Per task

| Lane | Do | Review |
|---|---|---|
| direct | inline; test first if testable; verify with the change's own evidence | none |
| standard | inline; test-driven where it applies (`${CLAUDE_PLUGIN_ROOT}/skills/test-driven-development/SKILL.md`) | one `overdrive:reviewer` at slice end, by surface |
| critical | one `overdrive:builder` per task, in order, from a brief; ledger `Task N: in-progress critical` | `overdrive:critical-reviewer` after each task, then the fix loop |

Critical tasks need the plan approved by the user before they start. Ask for it once, then keep building every independent non-critical task while you wait. [references/approval-while-building.md](references/approval-while-building.md)

Critical review and fix loop: the reviewer writes findings; rounds 1 and 2 resume the same builder with the findings file; round 3 is a fresh builder with `model: opus`; if findings remain, that is a ledgered ruling or a stop condition, never a fourth round. Stop an agent only when it loops (same check fails 3 attempts in a row, or 3 fix rounds without fewer failures); builders never wait on CI, you watch it in the background. [references/fix-loop.md](references/fix-loop.md)

## Slice

1. Plans with 3 or more tasks: preflight first, a table of what each task produces and consumes, conflicts written to the ledger as `Preflight:` lines. [references/preflight.md](references/preflight.md)
2. Execute the tasks in order, one at a time (a resumed run starts at `next`). [references/resume.md](references/resume.md)
3. Standard slice: one `overdrive:reviewer` on the slice package. Critical slice: `overdrive:final-reviewer` on the slice package, one fix wave, one scoped re-review. [references/final-review.md](references/final-review.md)
4. Reclassify the real diff (rule 7). Deliver through `${CLAUDE_PLUGIN_ROOT}/skills/release-gates/SKILL.md` (PR and merge).
5. Close with the summary: `OD ledger rulings` verbatim, anything BLOCKED with its command, and the Risk line `OD risk` prints for the final diff, `Risk: <lane> — <items | none>`.

## Excuses that do not change the rules

| Excuse | Reality |
|---|---|
| "It is only a few lines, skip the review." | Lane comes from what the change touches, never from its size. Two lines in billing are critical. |
| "The user approved the plan, review is redundant." | Approval is of the plan; the review reads the diff. |
| "This task is big, dispatch a builder." | Size is not a reason. Only critical isolation, parallel independent work or the context backstop. |
| "I need sudo / a package, I will just run it." | Not yours to change. BLOCKED with the exact command, continue elsewhere. |
| "The plan names it two ways, I should ask." | Pick the reading the rest of the plan uses, write the Ruling, continue. |
| "Task 1 looks wrong, I will redo it while here." | The ledger says complete. Add a Note and a Ruling; reopen only for a reviewer finding. |
