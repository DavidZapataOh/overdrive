# Overdrive

`overdrive` below means `{{PLUGIN_ROOT}}/bin/overdrive` (not on PATH).

Questions and explanations are read-only: answer and change nothing.

Before the first edit of any repo change, load overdrive:risk-triage and classify in the repo (or add `--repo <dir>`):
`overdrive risk --intent '<request>' --paths <files you expect to touch>`
Lane = max(script, your judgment): raise it for risk the script misses, never lower it; failed classification = critical. The user may raise any lane; a floor drops only on their explicit yes to the risk you state, recorded as a decision: the Risk line ends `(lowered by user, D-NNNN)`.

| Lane | When | Plan | Tests | Review |
|---|---|---|---|---|
| direct | clear in one read, no risk items | none | test first if testable | none |
| standard | neither | short decision plan | TDD where it applies | one per slice |
| critical | a floor or a risk-map rule | full TDD plan; ask approval, keep building independent work | TDD, hard cases, real deps | per task + final (opus) |

Direct lane: classification is the only process step, no other skill; verify inline.

Floors (always critical): irreversible data or migrations, auth and tenant isolation, money, secrets, security and CI/delivery, public contracts, concurrency, changes no test would catch.

End every change with the Risk line `overdrive risk` prints: `--worktree` if uncommitted, `--diff <base>...HEAD` if committed: `Risk: <lane> — <items | none>`. Never merge below the real diff's lane.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Skills (overdrive:<name>): new non-trivial work → intent-discovery; plan → decision-planning; testable change → test-driven-development; build → risk-scaled-execution; independent tasks → parallel-execution; review → risk-scaled-review; bug → root-cause-debugging; decisions, copy, product choices → decision-log; after corrections → compound-learning; before saying done → evidence-based-verification. User-only, read {{PLUGIN_ROOT}}/skills/<name>/SKILL.md when needed: research → deep-research; PR, merge, deploy → release-gates; writing a skill → skill-evaluation.

If you were dispatched with a brief, follow the brief instead of this routing.
