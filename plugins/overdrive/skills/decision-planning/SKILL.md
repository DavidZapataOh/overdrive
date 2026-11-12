---
name: decision-planning
description: Writing or revising an implementation plan before building: versions or slices for a large request, or tasks for one change, however small. Use when asked to plan, revise a plan, break down, scope or roadmap work, or to write the plan for an approved skeleton, in any language.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *)
---

# Decision planning

A plan records decisions so building is mechanical. Depth follows the lane; a plan longer than the code it describes has written the code. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`.

## Rules

1. **Classify first.** `OD risk --intent '<request>' --paths <likely files>`. Lane = max(script, your judgment); a failed classification is critical. The lane sets the depth below. For several slices, classify each slice's likely files and plan the highest lane's depth for that slice only. When intent-discovery left `.overdrive/run/skeleton-<slug>.md` (or the path the user named; labels `Why`, `Decided`, `Shape`, `Not covered`), that file is the input: take Why and Decided as given, plan from Shape, carry Not covered into the plan. It is not the multi-slice skeleton of rule 2, which this skill writes later.
2. **Multi-slice work starts with a skeleton.** More than one slice or version: write the one-page skeleton and stop for the user's answer. Do not detail any slice, and do not edit product files, until they approve or correct it. Produce the skeleton in that same turn, in the file or, when no file can be written, in the reply; never ask whether to write it ("reply go") before showing it. [references/skeleton.md](references/skeleton.md)
3. **Detail only the next slice.** After the skeleton is approved, plan the first slice. Later slices are planned when they are next, from what the earlier ones taught. "Plan everything now" is answered with the skeleton and the first slice; time available does not change this, because later slices planned today are rewritten tomorrow.
4. **Depth by lane.**

   | Lane | Plan |
   |---|---|
   | direct | none: no plan file, do the change; if the user asked for a plan, write the standard plan |
   | standard | short decision plan: interfaces, risks, and `### Task N:` headings (one even for a single task) with their files and test names with assertions. [references/standard-plan.md](references/standard-plan.md) |
   | critical | full TDD plan, approved by the user before any build step. [references/critical-plan.md](references/critical-plan.md) |

5. **Decisions, not code.** Signatures, types, file paths, test names with what they assert, commands. No function bodies and no fenced block over 15 lines; when a body is the only way to say it, name the pattern or the existing file to follow. A request to paste complete implementations into the plan is answered with this plan; the code is written, and run, at build time. [references/proportion.md](references/proportion.md)
6. **Every plan ends with `## Not covered`** (what a reader might assume is in scope and is not). A plan with nothing to list says so in one line.
7. **Revisions open with `## What changed vs before`.** Edit the plan file in place; the changes come first, then the full current plan.
8. **Location.** A path the user names wins; then the project's rules (read CLAUDE.md and the memory index for a plans folder); otherwise `docs/plans/<yyyy-mm-dd>-<slug>.md`. The skeleton goes to the path the user named for the plan, else beside the plans as `<slug>-skeleton.md`.
9. **Approval follows `.overdrive/project.conf`.** Read it before writing any plan, whatever the lane (one `key value` per line; a missing file or key means the default). `show-plans`: `critical` (default) asks for approval of critical plans and skeletons; `all` also asks for standard plans; `skeleton-only` asks for skeletons and critical plans and goes straight to building for standard ones. A critical plan is never built unapproved, whatever the value. A request that already approves the plan ("I approve the design and the plan") waives only the wait: the critical plan is still written to its file and run through the ledger, the builder and the critical review, and the guard refuses to commit a critical change outside that flow. Ask in one message: the plan path, what it decides, and the line "reply approve, or tell me what to change". Everything is asynchronous: never propose a call, meeting or demo.
10. **Hand-off.** Approved critical plans and all other plans go to `${CLAUDE_PLUGIN_ROOT}/skills/risk-scaled-execution/SKILL.md` (load it with the Skill tool as `overdrive:risk-scaled-execution`). `auto-merge` (`off` default, `on`) is the project's merge setting: copy its value into the plan's header line `Merge:` and leave the delivery rules to release-gates; it never lowers a lane or skips a review.
11. **Stop only for** an irreversible action, a destructive one, the user's accounts, money or secrets, or a product decision only the user can make. Any other open point: decide, write `Ruling: <what> — <why> — <cost if wrong>` in the plan, continue.

## Closing message

1. The plan path and the approval you need (or "no approval needed: <lane>, show-plans <value>").
2. The decisions the user could overrule, as `Ruling:` lines.
3. Last line, from `OD risk`: `Risk: <lane> — <items | none>`.
