---
name: risk-scaled-review
description: Reviewing a code change before merge or delivery: a branch, PR, diff or commit range, whether the user's or an agent's. Use when asked to review, check or look over changes for bugs, risks or readiness to merge, in any language.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *)
---

# Risk-scaled review

Reviews a change at the depth its lane calls for and returns findings in one format. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. This skill reports; it fixes only when the lane's executor does (see Rounds).

## Rules

1. **Package first.** `OD review-package --base SHA --head SHA [--brief FILE]` prints the package path (for "review my branch": base is `git merge-base main HEAD`, head is the branch tip). Read it: the `Lane:` line is the depth, the `Risk:` line the items. Lane = max(package, your judgment). Nothing lowers it: not size, urgency, the author's or an approver's sign-off, or who is asking.
2. **Depth follows the lane.**

   | Lane | Review |
   |---|---|
   | direct | no separate reviewer: read the diff yourself, run the change's own check, report with the findings format |
   | standard | `overdrive:reviewer` per roster lens |
   | critical | `overdrive:critical-reviewer` per roster lens; a whole slice also gets `overdrive:final-reviewer` |

   In the standard and critical lanes the dispatched agents review; reading the diff and writing findings yourself is not that review. Your own read comes first, to size the roster and to judge their findings. Dispatch every lens at once, then wait for all of them before merging or giving a verdict.

3. **Roster by surface.** Correctness always. Add a lens only when the package's items or stat name it, and say why in one line each: `Roster: <lens> — <why>`. An absent surface is skipped without a line. Lenses, triggers and the dispatch prompt: [references/roster.md](references/roster.md)
4. **Read the diff, never the author's report.** Compare each new query, endpoint or handler with its sibling code: every guard a neighbour applies (tenant filter, auth check, idempotency key, transaction) and this one lacks is a finding until shown otherwise.
5. **Findings have one format and anchors.** `F<n> | P0..P3 | 0|25|50|75|100 | path:line | title | "verbatim quote" | failure mode | fix | plan-mandated:yes|no`. At 75 or more, quote the line; suppress 25 and below; 50 only for P0. No "consider" without a failure mode, no style opinion without a rule. Details: [references/findings.md](references/findings.md)
6. **Mechanics are the script's, meaning is yours.** `OD findings check FILE` on every reviewer file, `OD findings merge FILE...` for dedupe and sort. Then remove semantic duplicates (same defect, different title or line) from the merged list yourself, keeping the higher severity. Before merging, confirm every lens's file exists and that the files are distinct paths (an empty file is a valid "no findings"; a missing one means that reviewer has not reported, so wait or ask it again). Never edit a reviewer's own file.
7. **A rationale never downgrades.** "Intentional", "approved", "finance reconciles", "demo in an hour" go next to the finding as context. Each finding has one severity (never "P1 or P2") from its failure mode, and the verdict follows the findings: any open P0 or P1 means not ready to merge. The owner may accept the risk in their own words; you record that as a `Ruling:`, you do not soften the finding.
8. **Plan-mandated defects are reported.** A defect the plan itself asks for is a finding with `plan-mandated:yes`.
9. **Reviewers never run the full suite.** A reviewer reruns at most one focused test; the critical reviewer reruns the recorded evidence commands once. Passing tests are not a verdict.
10. **Bounded rounds, no nesting.** Standard: one fix wave and one scoped re-review. Critical: at most 3 rounds per task. [references/rounds.md](references/rounds.md) Reviewers never dispatch reviewers; if you are a subagent, review yourself and dispatch nothing.

## Closing message

1. Verdict: `Ready to merge` or `Not ready: <open P0/P1 count>`.
2. The `Roster:` lines, then the merged findings file path (the path the user named, else beside the package) and counts per severity.
3. Rulings, if any, as `Ruling: <what> — <why> — <cost if wrong>`.
4. Last line, from the package: `Risk: <lane> — <items | none>`.
