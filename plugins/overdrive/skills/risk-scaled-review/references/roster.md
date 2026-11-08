# Roster

## Contents

- Lenses
- Dispatch prompt
- Cost rules

## Lenses

Correctness always runs. The others run only when the package says so. Items are those on the package's `Risk:` line.

| Lens | Add when | Looks for |
|---|---|---|
| correctness | always | wrong behavior users will hit, missing guards compared with sibling code, races, double charges, error paths |
| security | `auth`, `secrets` or `tenant-isolation` | missing or weakened authentication and authorization, another customer's data reachable, secrets in code or logs |
| data | `data-migration` | irreversible or locking migrations, `NOT NULL` without a default or backfill, lost columns, no rollback |
| contract | `public-contract` | breaking changes to an API, schema or exported symbol that other code consumes |
| tests | a test file is in the diff stat, or `test-removed`, `untested-change` or `test-harness` is listed | tests that would still pass with the defect, deleted or skipped cases, missing regression cases |

`money`, `concurrency`, `delivery` and `dependencies` items are read by the correctness lens; a critical reviewer already looks first for double charges, races and secrets. Do not add a lens for an item that is not in the table.

A migration-only diff is therefore two reviewers (correctness and data). Print the lines as:

```
Roster: correctness — always
Roster: data — data-migration in the package
```

Each line starts at the left margin with `Roster:` (no bullet). Print no line for a lens that was not added.

## Dispatch prompt

The agent is `overdrive:reviewer` in the standard lane and `overdrive:critical-reviewer` in the critical lane; dispatch every lens in one message. Pass paths, never pasted diffs:

```
Package: <package path>
Lens: <lens>. Review only for what the lens looks for; report anything else you notice only if it is P0.
Write your findings to <package path without .md>-<lens>.findings
```

Before merging, confirm that each lens has its own file and that no two lenses share a path: `ls` the expected names. A missing file is a reviewer that has not reported. Then run `OD findings check` on each file and `OD findings merge` on all of them.

## Cost rules

- A lens costs a reviewer. A lens without a trigger in the table is not worth it.
- Direct lane: no reviewer, no roster lines.
- `overdrive:final-reviewer` is for a whole critical slice from a plan (its executor dispatches it), not for a single branch.
