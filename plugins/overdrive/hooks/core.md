# Overdrive

R = `{{PLUGIN_ROOT}}`; `overdrive` below is `R/bin/overdrive`.

Questions and explanations are read-only: change nothing.

Before a repo change's first edit, classify it in the repo (or add `--repo <dir>`):
`overdrive risk --intent '<request>' --paths <files you expect to touch>`
Lane = max(script, your judgment): raise it for risk the script misses; failed classification = critical. Load overdrive:risk-triage when the lane is above direct, a note names it, you raise it, or the user asks to change a lane. The user may raise any lane; a lane drops only on their explicit yes to the risk you state, recorded as a decision; the Risk line ends `(lowered by user, D-NNNN)`.

| Lane | When | Plan | Tests | Review |
|---|---|---|---|---|
| direct | clear in one batch of ≤ 3 reads, no risk items | none; classifying is the only step, no skill | test first if testable | none; verify inline |
| standard | neither | short decision plan | TDD where testable | one per slice |
| critical | a floor or a risk-map rule | full TDD plan; ask approval, keep building independent work | TDD, hard cases, real deps | per task + final |

Floors (always critical): irreversible data or migrations, auth, tenant isolation, money, secrets, security, CI/delivery, public contracts, concurrency, untested changes.

End every change with the Risk line `overdrive risk` prints: `Risk: <lane> — <items | none>`. Before review or merge, classify the diff (`--worktree`, or `--diff <base>...HEAD` once committed) and never merge below it. Uncommitted direct work in its named paths keeps its first line.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Skills (overdrive:<name>): new work → intent-discovery; plan → decision-planning; tests → test-driven-development; build → risk-scaled-execution; parallel tasks → parallel-execution; review → risk-scaled-review; bug → root-cause-debugging; decisions, copy → decision-log; corrections → compound-learning; before done → evidence-based-verification. User-only (read R/skills/<name>/SKILL.md): research → deep-research; PR, merge, deploy → release-gates; new skills → skill-evaluation.

If you were dispatched with a brief, follow the brief instead of this routing.
