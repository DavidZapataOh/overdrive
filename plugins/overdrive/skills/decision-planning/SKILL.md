---
name: decision-planning
description: Writing or revising an implementation plan before building: splitting a large request into versions or slices, or planning one change, task by task. Use when asked to plan, break down, scope or roadmap work, or to write the plan for an approved skeleton, in any language.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *) Bash(git *)
---

# Decision planning

A plan records decisions so building is mechanical. Depth follows the lane; a plan longer than the code it describes has written the code. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`.

## Rules

1. **Classify first.** `OD risk --intent '<request>' --paths <likely files>`. Lane = max(script, your judgment); a failed classification is critical. The lane sets the depth below. For several slices, classify each slice's likely files and plan the highest lane's depth for that slice only.
2. **Multi-slice work starts with a skeleton.** More than one slice or version: write the one-page skeleton and stop for the user's answer. Do not detail any slice, and do not edit product files, until they approve or correct it. [references/skeleton.md](references/skeleton.md)
3. **Detail only the next slice.** After the skeleton is approved, plan the first slice. Later slices are planned when they are next, from what the earlier ones taught. "Plan everything now" is answered with the skeleton and the first slice; time available does not change this, because later slices planned today are rewritten tomorrow.
4. **Depth by lane.**

   | Lane | Plan |
   |---|---|
   | direct | none: no plan file, do the change; if the user asked for a plan, write the standard plan |
   | standard | short decision plan: files, interfaces, test names with assertions, risks. [references/standard-plan.md](references/standard-plan.md) |
   | critical | full TDD plan, approved by the user before any build step. [references/critical-plan.md](references/critical-plan.md) |

5. **Decisions, not code.** Signatures, types, file paths, test names with what they assert, commands. No function bodies and no fenced block over 15 lines; when a body is the only way to say it, name the pattern or the existing file to follow. [references/proportion.md](references/proportion.md)
6. **Every plan ends with `## Not covered`** (what a reader might assume is in scope and is not). A plan with nothing to list says so in one line.
7. **Revisions open with `## What changed vs before`.** Edit the plan file in place; the changes come first, then the full current plan.
8. **Location.** A path the user names wins; then the project's rules (read CLAUDE.md and the memory index for a plans folder); otherwise `docs/plans/<yyyy-mm-dd>-<slug>.md`. The skeleton goes to the path the user named for the plan, else beside the plans as `<slug>-skeleton.md`.
9. **Approval follows `.overdrive/project.conf`.** Read it when it exists (one `key value` per line; missing file or key means the default). `show-plans`: `critical` (default) asks for approval of critical plans and skeletons; `all` also asks for standard plans; `skeleton-only` asks for skeletons and critical plans and goes straight to building for standard ones. A critical plan is never built unapproved, whatever the value. Ask in one message: the plan path, what it decides, and the line "reply approve, or tell me what to change". Everything is asynchronous: never propose a call, meeting or demo.
10. **Hand-off.** Approved critical plans and all other plans go to `${CLAUDE_PLUGIN_ROOT}/skills/risk-scaled-execution/SKILL.md` (load it with the Skill tool as `overdrive:risk-scaled-execution`). `auto-merge` (`off` default, `on`) is the project's merge setting: copy its value into the plan's header line `Merge:` and leave the delivery rules to release-gates; it never lowers a lane or skips a review.
11. **Stop only for** an irreversible action, a destructive one, the user's accounts, money or secrets, or a product decision only the user can make. Any other open point: decide, write `Ruling: <what> — <why> — <cost if wrong>` in the plan, continue.

## Closing message

1. The plan path and the approval you need (or "no approval needed: <lane>, show-plans <value>").
2. The decisions the user could overrule, as `Ruling:` lines.
3. Last line, from `OD risk`: `Risk: <lane> — <items | none>`.
