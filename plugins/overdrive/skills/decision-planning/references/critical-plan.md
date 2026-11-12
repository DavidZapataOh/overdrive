# Critical plan

## Contents

- Header
- Sections in order
- Task shape
- Approval

A critical change is planned in full and approved before any build step. The plan is complete enough that an executor with no memory of the conversation can do each task from its brief.

## Header

```
# <Change>: implementation plan

Lane: critical — <items from OD risk>
Merge: <auto-merge value from project.conf, default off>
Spec: <path to the spec or request this implements>
```

## Sections in order

1. `## Global Constraints`: the rules every task must obey, copied verbatim from the spec, CLAUDE.md and the decisions log (quote, do not paraphrase; name the source after each). `OD brief` copies this section into every task brief, so it must stand alone.
2. `## Review Focus`: the 3 to 6 things a reviewer must check hardest, each tied to a floor or a risk-map item (isolation between customers, money, irreversible data, public contract, concurrency, untested paths), with the hard cases that prove it.
3. `## File Structure`: every file created or modified, one line each with its responsibility, grouped by task.
4. Tasks, in build order.
5. `## Not covered`.

## Task shape

```
### Task N: <title>

**Files:**
- Create: `path`
- Modify: `path`
- Test: `path`

**Interfaces:** names, signatures and types this task provides and consumes.

- [ ] **Step 1: Write the failing test** `test name`: what it asserts, and the command that runs it.
- [ ] **Step 2: Run it and see it fail** for the stated reason.
- [ ] **Step 3: Implement** the minimum, described in prose, by the interface and the file to follow.
- [ ] **Step 4: Run it and see it pass**, then the neighbouring tests.
- [ ] **Step 5: Commit** with the message.
```

Rules: tests come first and include the hard cases (the other tenant, the retry, the rollback, the empty input); real dependencies for what the floor protects, not mocks; one commit per task; a task touches one concern. Order irreversible steps last and give each a rollback or a stated reason there is none.

## Approval

Critical plans wait for the user's approval, whatever `show-plans` says. Send the `Plan:` paragraph that risk-triage rule 4 describes (the path, one line per task with its key test, "reply approve, or tell me what to change"), then the Global Constraints source and the Review Focus in one line each. Independent non-critical work can proceed while waiting (see `${CLAUDE_PLUGIN_ROOT}/skills/risk-scaled-execution/references/approval-while-building.md`). A change request becomes a revision with `## What changed vs before`.
