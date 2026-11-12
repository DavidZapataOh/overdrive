# Lanes

Every repository change is handled in one of three lanes. The lane sets how much planning, review and evidence the change needs; nothing else does. This page is the reference. The rule grammar is in [risk-map.md](risk-map.md), the hook that enforces the critical lane in [guard.md](guard.md), the decision log in [decisions.md](decisions.md) and the agents' models in [model-policy.md](model-policy.md).

| Lane | Meant for | Plan | Tests | Review |
| --- | --- | --- | --- | --- |
| `direct` | a fix or adjustment that is clear after at most three reads and raises no risk item; new behavior is at least standard | none | test first if testable; otherwise `TDD: n/a — <reason>` | none; reread the diff and run the change's own check |
| `standard` | work that is neither trivial nor risky | short decision plan | test-driven where it applies | one `overdrive:reviewer` per slice, before any pull request |
| `critical` | a floor or a project risk-map rule | full test-first plan, approved by the user before the critical part is touched | test-driven with a hard-case list, real dependencies you own and a non-regression check | `overdrive:critical-reviewer` per task and after every change, then one `overdrive:final-reviewer` on the slice |

## How the classifier picks a lane

`overdrive risk` decides from facts. It reads one or more of:

- a committed range (`--diff A..B` or `A...B`), the index (`--staged`) or the working tree (`--worktree`: tracked changes against `HEAD` plus untracked files);
- paths named before any change exists (`--paths`);
- the request text before any work starts (`--intent`).

Each rule that matches raises an item with a lane, `critical` or `standard`. The change's lane is the highest lane among its items, and `direct` when there are none. Size never counts: two lines in a billing module are critical. The output lists `lane`, `item`, `note` and `next` lines and ends with `Risk: <lane> — <items | none>`, critical items first. It exits 0 when classified, 3 when classification failed and 64 on a usage error.

### Floors

The floors in `plugins/overdrive/lib/floors.conf` apply to every project and cannot be removed. A project adds rules in `.overdrive/risk-map.conf`. Both are read on every side of the change and joined, so a change cannot lower its own lane by editing the map; editing the map is itself the critical item `risk-map`.

| Item | Lane | Raised by (examples) |
| --- | --- | --- |
| `data-migration` | critical | migration directories, `*.sql`, `schema.prisma`, `drizzle/`, `alembic/`; added `DROP TABLE`, `DROP COLUMN`, `ALTER TABLE`, `TRUNCATE`, `DELETE FROM` |
| `auth` | critical | path words such as `auth`, `session`, `permission`, `rbac`, `oauth`, `jwt`, `login`, `password`, `credential`; `bcrypt`, `argon2`, `verifyToken`, `getServerSession` |
| `tenant-isolation` | critical | `tenant`, `rls` in a path; `tenant_id`, `tenantId`; row-level security and `CREATE POLICY` statements |
| `money` | critical | path words such as `billing`, `payment`, `checkout`, `invoice`, `subscription`, `refund`, `payout`, `charge` |
| `secrets` | critical | `.env*`, `*.pem`, `*.key`, names containing `secret`, `credentials*`; provider key formats and private-key headers in added lines; quoted credentials assigned to `api_key`, `secret`, `token` or `password` |
| `delivery` | critical | `.github/workflows/`, `Dockerfile*`, deploy and hook configuration, `CODEOWNERS`, dependency-bot configuration; a `package.json` that adds a `vercel-build`, `deploy`, `release`, `predeploy` or `postdeploy` script |
| `risk-map` | critical | `.overdrive/risk-map.conf` |
| `public-contract` | critical | `*.proto`, `*.graphql`, `openapi*`, `swagger*`, `api/` directories |
| `concurrency` | critical | `FOR UPDATE`, `SKIP LOCKED`, advisory locks, mutexes, semaphores, `Atomics.`, serializable isolation |
| `dependencies` | standard | `package.json` and lock files, `go.mod`, `Cargo.toml`, `requirements*.txt`, `pyproject.toml`, `Gemfile*` |
| `test-harness` | standard | `vitest`, `jest`, `playwright` and `pytest` configuration, `conftest.py`, `turbo.json` |

The list is abbreviated; `floors.conf` is the source. Words in documentation files (`.md`, `.mdx`, `.rst`, `.adoc`) do not raise path-token items, so `docs/payments.md` is prose and not money code.

### Items the classifier computes from the change

| Item | Lane | Raised when |
| --- | --- | --- |
| `test-removed` | critical | a test file is deleted or renamed to a non-test name, a test file loses more test cases than it gains, or a skip or `only` marker is added without replacing a removed case |
| `unscanned-content` | critical | a changed file git shows as binary, though its name is not a binary format |
| `untested-change` | critical | a changed source file that no test covers (rules for coverage in [risk-map.md](risk-map.md)) |
| `deletion` | standard | a deleted file that is not a test |
| `exec-bit` | standard | an existing file made executable |
| `classification-failed` | critical | the classifier could not run to the end; the lane is never picked by hand |

### Judgment

The classifier reads paths, lines and words, not meaning. Claude therefore holds the lane at the maximum of the script and its own judgment, and may only raise it. Typical raises:

- a one-off script that deletes or rewrites production data (`data-migration`);
- a permission or ownership check in a file whose name says nothing about auth (`auth`);
- a query that drops or widens a per-customer filter (`tenant-isolation`);
- a field, endpoint or event that another service or customer consumes (`public-contract`);
- price, discount, rounding or currency arithmetic outside a billing path (`money`);
- shared state touched from parallel jobs, retries or webhooks (`concurrency`).

A change that one batch of at most three reads does not explain, or that a person could not finish from the request and `git diff` alone, is at least `standard`. The raised item is appended to the Risk line after the classifier's items.

The change is classified twice: before its first edit, from the request and the files expected, and again on the real diff before review or merge. If the diff classifies above the lane the work was done under, new work stops, the affected part gets the tests and review of the new lane, the rest of the slice is replanned, and the Risk line is updated. A change is never merged below the lane of its diff. The Stop hook enforces the last rule: a turn that changed a repository ends with a Risk line, and a line below a fresh classification is blocked.

## Direct

Classify once, inside the paths the classification named. Make the change inline, test first when a test can reach it, and verify with the change's own evidence: reread the diff and run its test. No plan file, no agent, no skill. The Stop hook reclassifies the working tree when the turn ends.

## Standard

1. A short decision plan with one `### Task N:` heading per task (even for a single task), the files each touches and the tests with their assertions.
2. Build inline, test-driven where a test command exists: tests committed alone, pinned, red evidence, minimal implementation, green evidence on the whole suite, `overdrive pin --clear`.
3. After the slice's last commit, `overdrive evidence green -- <test command>` (or `--no-tests <reason>` when nothing is testable).
4. `overdrive review-package --base SHA --head SHA --brief FILE --require-green`, then one `overdrive:reviewer` per surface. P0 and P1 findings are fixed in one wave, followed by one scoped re-review whose base is the head the first review read.
5. Reclassify the diff, then deliver through the pull request flow of `release-gates`.

## Critical

A critical change is built only after the user approves its plan, and it cannot reach its final review or its pull request while any critical task lacks a review of its latest state.

1. **Classify before the first edit.** Nothing that changes a file runs first.
2. **Plan for approval.** The full test-first plan is written to its plan file, and the reply opens with a `Plan:` paragraph: the file path, one line per task with its key test, and the ask "reply approve, or tell me what to change". Work that does not depend on the critical part may continue while the plan waits; the critical part itself, including a script or a migration that has not run yet, waits for the approval.
3. **Open the ledger.** `overdrive ledger init --plan FILE` makes the plan's ledger the active one; with three or more tasks a preflight table of what each task produces and consumes is written to it first.
4. **Per task.** Classify the task (`overdrive risk --intent <title> --paths <its files>`). `overdrive brief --plan FILE --task N` writes the brief and, for a critical task, adds `Task N: in-progress critical` to the ledger. The task is always built by one `overdrive:builder`, however small, with tests first: a list of hard cases written before the first test, tests committed and pinned, red evidence, the implementation, a non-regression check (the new tests fail on the previous code, the old suite passes on the new code), then green evidence on the whole suite.
5. **Critical review of the task.** `overdrive review-package --base <task base> --head HEAD --brief FILE --lane critical`, then `overdrive:critical-reviewer` dispatched with `Task N` in its description. The reviewer reruns the task's red and green evidence and writes findings in the nine-field format, which `overdrive findings check` and `merge` validate and sort.
6. **Fix loop, with a new review after every change.** With P0 or P1 findings, the same builder is resumed with the findings file in rounds 1 and 2, and a fresh builder on `opus` takes round 3. Each builder dispatch is recorded as a change, so each fix needs a new `overdrive:critical-reviewer` dispatch that names the task. Findings still open after round 3 end in a ruling (`Ruling: <finding> accepted — <why> — <cost if wrong>`) or, for a P0 on money, data, secrets or tenant isolation that the plan cannot fix, a stop and a question to the user. A task is `complete` only when its last review has no P0 or P1 and both verdicts pass.
7. **One final review.** After the last task, `overdrive evidence green -- <test command>` at the slice's last commit, then `overdrive review-package --base SLICE_BASE --head HEAD --brief FILE --lane critical --require-green`, then `overdrive:final-reviewer` on that package. Its P0 and P1 findings are fixed in one wave and checked by one scoped `overdrive:critical-reviewer` pass on a package that holds only the fix wave. There is no second wave.
8. **Reclassify the diff, then the pull request.** `overdrive risk --diff BASE...HEAD`, the review on record for the head, the Risk line in the PR body, and the steps of `release-gates`. A critical pull request is one per task and never mixed with other work. A merge is automatic only when `.overdrive/project.conf` says `auto-merge on`, and never before the head's review is on record.

### What enforces it

The skills carry the steps; the guard enforces the ordering that must not depend on Claude's discipline. While the active ledger holds a critical task with no `reviewed by critical-reviewer` line after its last change:

- the PreToolUse hook denies dispatching `overdrive:final-reviewer` and denies `gh pr create` and `gh pr merge`;
- `overdrive review-package --require-green` in the critical lane exits 65;
- the PreToolUse hook classifies each `git commit` and denies one whose content has a critical domain item (not `untested-change` alone, and not the risk map) unless the critical flow is under way: the commit comes from the dispatched `overdrive:builder`, the active ledger of the branch (any branch while a merge is concluded) has a task marked critical (`overdrive ledger critical-flow`), or the commit message cites `(lowered by user, D-NNNN)` for an active decision that lowers a lane. A request that already approves the plan ("I approve the design and the plan; use your default execution method") approves the plan's content and waives the wait for approval; it does not skip the plan file, the ledger, the builder or the critical review, and building the change inline ends in a denied commit.

The guard writes the review and change records itself. Dispatching `overdrive:critical-reviewer` with `Task N` in its description (or a `task-N` brief path in its prompt) records `Task N: reviewed by critical-reviewer`; dispatching `overdrive:builder` the same way records `Task N: changed by builder`, which makes the task need a new review. A `Task N: reviewing` line written by hand is only a state, `overdrive ledger add` refuses the guard's record lines, and a file tool cannot write the ledger. Details, the branch binding and the known limits (a review is recorded by the dispatch and not by its verdict; pull requests made outside the shell are not seen; a ledger that cannot be read lets the call through) are in [guard.md](guard.md#critical-lane-gate).

## Lowering a lane

Only the user lowers a lane, and only by answering the risk that Claude states. A request to skip the process ("no ceremony", "treat it as direct") is not that answer. Before any edit:

1. Claude states the concrete risk in at most two sentences: what breaks, for whom, and whether it can be undone.
2. It asks once, with the line `Confirm you want this handled as <lane> anyway?`, and the change keeps its lane until the reply.
3. On an explicit yes, Claude takes the next ID from `overdrive decisions next-id`, appends an entry to `.overdrive/decisions.md` that quotes the reply verbatim as `Source`, and runs `overdrive decisions check`.
4. It makes the change and ends with the lane the user chose, the classifier's items unchanged and the decision: `Risk: direct — data-migration (lowered by user, D-0007)`.

A no, a counter-question or silence keeps the lane. The decision covers its scope only; the next change to the same files is classified from scratch. The Stop hook accepts a Risk line below the classifier's only when it cites an active decision whose quote is attributed to someone other than the agent. The entry format is in [decisions.md](decisions.md).

Anyone may raise a lane at any time, and Claude raises it without asking.

## Ledger lines

The ledger of a plan lives at `.overdrive/run/<plan-stem>-<cksum>/ledger.md` and starts with `# Overdrive ledger — plan: <absolute plan path>`. `overdrive ledger add LINE` appends one of:

| Line | Meaning |
| --- | --- |
| `Task N: pending`, `in-progress`, `implemented`, `reviewing`, `fixing round K`, `complete`, `blocked <text>` | the state of task N; `reviewing` is a state and not a review |
| `Task N: in-progress critical` | marks task N critical; written by `overdrive brief` or `overdrive ledger mark-critical N` |
| `Task N: reviewed by critical-reviewer` | written by the guard when `overdrive:critical-reviewer` is dispatched for task N |
| `Task N: changed by builder` | written by the guard when `overdrive:builder` is dispatched for task N |
| `Ruling: <what> — <why> — <cost if wrong>` | a decision made without asking; `overdrive ledger rulings` prints them for the closing summary |
| `Preflight: <text>`, `Note: <text>` | the preflight table and free notes |
| `Run: branch <name>` | binds the ledger to the run's branch; written by `ledger init` on a non-default branch or by the first `ledger add` made on one |
| `Run: closed — <reason>` | the run was abandoned; other branches are no longer gated, the run's own branch stays gated |

`overdrive ledger status` prints the last state of every task and a `next` line, the first task not `complete`; a task the ledger shows `complete` is never reopened. `overdrive ledger unreviewed [--all-started] [--any-branch]` lists the tasks the guard counts as unreviewed: critical tasks with no review after their last `in-progress`, `implemented`, `fixing round` or `changed by builder` line, and critical tasks stay listed after `complete` until a review follows their last change. `--all-started` adds started tasks that are not marked, `complete` or `blocked`, which is what the final-review gate uses. Tasks that never started, tasks that are only blocked, and ledgers bound to another branch print nothing without `--any-branch`.
