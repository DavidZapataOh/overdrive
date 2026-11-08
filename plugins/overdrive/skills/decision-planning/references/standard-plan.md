# Standard plan

A short decision plan, usually 30 to 60 lines, written to `<plans folder>/<yyyy-mm-dd>-<slug>.md`. It lets a reader who has not seen the conversation build the change and know when it is right.

```
# <Change>

Merge: <auto-merge value from project.conf, default off>

## Goal
One or two sentences: the behavior after the change.

## Interfaces
Signatures, types, config keys, endpoints: names and shapes only.

## Risks
Each risk: what could break, how a test or check would show it.

### Task 1: <title>

**Files:**
- Create: `path` (what it holds)
- Modify: `path` (what changes)
- Test: `path`

**Tests:**
- `test name`: what it asserts, in one line (input, expected result).

## Not covered
...
```

## Rules

- Tests are named and say what they assert; a test list without assertions is a wish list.
- Interfaces carry names, parameter and return types, and error cases. They never carry bodies.
- Reuse is written as a path: "follow `src/orders/list.js`" is a decision; copying its body into the plan is not.
- Risks come from `OD risk` items and from the sibling code: a guard the neighbours apply (tenant filter, auth, idempotency) is listed as a test.
- Task headings are always present, one for a single-task change: `risk-scaled-execution` reads `### Task N:` headings and the `Create:`, `Modify:`, `Test:` lines to build its ledger and briefs, and a plan without them has zero tasks. Split into several tasks only when parts can be built and checked independently.
