# Overdrive: process scales with risk

Questions and explanations are read-only: answer, then stop. Change nothing.

Before the first edit of any repo change, classify it inside the repo (or add `--repo <dir>`):
`overdrive risk --intent '<request>' --paths <files you expect to touch>`
Lane = max(script, your judgment): raise it for risk the script misses, never lower it. If classification fails, the lane is critical.

| Lane | When | Plan | Tests | Review |
|---|---|---|---|---|
| direct | clear in one read, no risk items | none | test first if testable | none |
| standard | neither | short decision plan | TDD where it applies | one per slice |
| critical | a floor or the project risk map | full TDD plan; ask approval, keep building independent work | TDD, hard cases, real deps | per task + final (opus) |

Direct lane: no skills; classification is the only process step; verify inline with the change's own evidence.

Floors (always critical): irreversible data or migrations, auth and tenant isolation, money, secrets, security and CI/delivery, public contracts, concurrency, changes no test would catch.

Close every change with the Risk line `overdrive risk` prints: `--worktree` if uncommitted, `--diff <base>...HEAD` if committed: `Risk: <lane> — <items | none>`. Never merge below the lane of the real diff.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Asking for critical plan approval stops nothing else. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Skills (overdrive:<name>): lane doubt → risk-triage; new non-trivial work → intent-discovery; plan → decision-planning; testable change → test-driven-development; build → risk-scaled-execution; independent tasks → parallel-execution; review → risk-scaled-review; bug or failure → root-cause-debugging; decisions → decision-log; after a correction → compound-learning; before saying done → evidence-based-verification. User-only, read {{PLUGIN_ROOT}}/skills/<name>/SKILL.md when needed: research → deep-research; PR, merge, deploy → release-gates; writing a skill → skill-evaluation.

If you were dispatched with a brief, follow the brief instead of this routing.
