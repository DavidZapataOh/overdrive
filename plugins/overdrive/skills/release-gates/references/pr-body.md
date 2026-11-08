# Pull request body

Write `.overdrive/run/pr-body.md` with these slots, in this order, nothing else. Every slot is mandatory; write `none` where there is nothing to say.

```markdown
## What
<one or two sentences: the change as a reader of the diff sees it>

## Why
<the problem or request that made it necessary>

Risk: <lane> — <items | none>

## Evidence
- <command that proves it, as run, and its result: `node --test` — 12 passed>
- <review: findings file path and verdict, for standard and critical>
- <files such as .overdrive/run/evidence/*-red.md and *-green.md when the work was test-first>

## Not covered
<what this change deliberately does not do, what was not tested, any Ruling that outlives the work; `none` only when true>
```

Rules:

- The `Risk:` line is the one `OD risk --diff BASE...HEAD` prints, copied verbatim, on its own line.
- Evidence is commands and paths a reader can run or open, with the outcome. "Tested" without a command is not evidence.
- The title is an imperative sentence with no prefix and no plan or task numbers.
- Keep the file out of the commit: `.overdrive/run/` ignores itself.
