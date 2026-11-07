# Overdrive: process scales with risk

Questions and explanations are read-only: answer, then stop. Change nothing.

Before the first edit of any repo change, classify it:
`overdrive risk --intent '<request>' --paths <files you expect to touch>`
Lane = max(script, your judgment): raise it when you see risk the script cannot, never lower it. If classification fails, the lane is critical.

| Lane | When | Plan | Tests | Review |
|---|---|---|---|---|
| direct | clear in one read, no risk items | none | test first if testable | none; evidence |
| standard | neither | short decision plan | TDD where it applies | one per slice |
| critical | a floor or the project risk map | full TDD plan, user approves | TDD, hard cases, real deps | per task + final (opus) |

Floors (always critical): irreversible data or migrations, auth and tenant isolation, money, secrets, security and CI/delivery, public contracts, concurrency, changes no test would catch.

Close every change with the Risk line printed by `overdrive risk --worktree` (a branch: `--diff <base>...HEAD`): `Risk: <lane> — <items | none>`. Never merge below the lane of the real diff.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Skills (overdrive:<name>): lane doubt → risk-triage; new non-trivial work → intent-discovery; plan → decision-planning; testable change → test-driven-development; build → risk-scaled-execution; independent tasks → parallel-execution; review → risk-scaled-review; bug or failure → root-cause-debugging; decisions → decision-log; after a correction → compound-learning; before saying done → evidence-based-verification. Read when needed: research → {{PLUGIN_ROOT}}/skills/deep-research/SKILL.md; PR, merge, deploy → {{PLUGIN_ROOT}}/skills/release-gates/SKILL.md; writing a skill → {{PLUGIN_ROOT}}/skills/skill-evaluation/SKILL.md.

If you were dispatched with a brief, follow the brief instead of this routing.
