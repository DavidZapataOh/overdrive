# Standard plan

A short decision plan, usually 30 to 60 lines, written to `<plans folder>/<yyyy-mm-dd>-<slug>.md`. It lets a reader who has not seen the conversation build the change and know when it is right.

```
# <Change>

Merge: <auto-merge value from project.conf, default off>

## Goal
One or two sentences: the behavior after the change.

## Files
- Create: `path` (what it holds)
- Modify: `path` (what changes)
- Test: `path`

## Interfaces
Signatures, types, config keys, endpoints: names and shapes only.

## Tests
- `test name`: what it asserts, in one line (input, expected result).

## Risks
Each risk: what could break, how a test or check would show it.

## Not covered
...
```

## Rules

- Tests are named and say what they assert; a test list without assertions is a wish list.
- Interfaces carry names, parameter and return types, and error cases. They never carry bodies.
- Reuse is written as a path: "follow `src/orders/list.js`" is a decision; copying its body into the plan is not.
- Risks come from `OD risk` items and from the sibling code: a guard the neighbours apply (tenant filter, auth, idempotency) is listed as a test.
- Task headings (`### Task N: <title>`) with `- Create:`, `- Modify:`, `- Test:` lines in backticks are used only when the change has several independently buildable parts, so `OD brief` can cut a brief from them.
