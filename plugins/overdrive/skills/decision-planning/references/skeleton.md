# Skeleton

## Contents

- When
- Shape
- Rules for each section
- Approval message

## When

A request that cannot ship as one change: several versions, several slices, or work whose later parts depend on what the first part teaches. One slice of one lane is a plan, not a skeleton.

## Shape

At most 80 lines, plain headings, no code. Write it to the path the user named for the plan, else `<plans folder>/<slug>-skeleton.md`.

```
# <Product or change>: skeleton

Merge: <auto-merge value from project.conf, default off>

## Objective
One sentence: what exists at the end and who it is for.

## Slices
| # | Version or slice | Objective | Scope (in) | Lane |
| 1 | ... | one line | one line | standard |

## Cost per month
| Item | Cost | Need it covers | Trigger to start paying |
Free items say "free" and no trigger. A paid item without a need and a trigger is removed.

## Patterns and bets
Proven patterns: N of M (name the pattern and where it is proven). Bets: each labeled "Bet:" with the cost if wrong.

## Open assumptions
Each one a line: the assumption, who or what confirms it, what changes if false.

## Not covered
What a reader might assume is in scope and is not.

## Approve?
Reply approve, or tell me what to change.
```

## Rules for each section

- Slices: each ends in something usable; the first is the smallest one that proves the riskiest assumption. Name a slice's lane from `OD risk` on its likely files.
- Cost: monthly money only, in the user's currency when known. Say the trigger as a measurable event (a sale count, a usage level), never "later".
- Patterns and bets: count what the project's decisions log, memory and neighbouring code already prove. A gap with no precedent is a bet and is labeled; do not hide bets among patterns.
- Assumptions: facts you could not read from the repo or decisions. A fact you can read is read, not listed.
- No slice detail: files, tests and steps belong to the plan of that slice.

## Approval message

Point at the file and put the slice table (objective and scope per slice) in the reply too, so the answer needs no second window; name the biggest bet and ask for the answer. Wait; do not start slice 1 on silence. Once approved, plan slice 1 only.
