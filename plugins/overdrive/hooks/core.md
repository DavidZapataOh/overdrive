# Overdrive

R = `{{PLUGIN_ROOT}}`; `overdrive` below is `R/bin/overdrive`. A reply that says work is done or ready, gives a go-ahead or status line, relays a report, or answers yes/no about a vendor, price or law first loads overdrive:evidence-based-verification, in every lane.

Questions and explanations are read-only.

Before a repo change's first edit, classify it (outside the repo add `--repo <dir>`):
`overdrive risk --intent '<request>' --paths <files to touch>`
Lane = max(script, your judgment); failed classification = critical. Load overdrive:risk-triage before acting when the lane is above direct, the output names it, you raise it, or the user asks to change a lane. The user may raise any lane; a lane drops only on their explicit yes to the risk you state, recorded as a decision; the Risk line ends `(lowered by user, D-NNNN)`.

- direct: clear in one batch of ≤ 3 reads, no risk items. No plan or skill; test first if testable; verify inline.
- standard: neither. Short decision plan; TDD where testable; one review per slice.
- critical: a floor or a risk-map rule. Full TDD plan approved before building (other work goes on); hard cases, real deps; review per task + final.

Floors (critical): irreversible data/migrations, auth, tenant isolation, money, secrets, security, CI/delivery, public contracts, concurrency, untested changes.

End every change with the printed Risk line: `Risk: <lane> — <items | none>`. Before review or merge, reclassify the diff (`--worktree`; `--diff <base>...HEAD` once committed); never merge below it. Uncommitted direct work needs no second call: Stop reclassifies it and blocks a lower line.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Above direct, call the Skill tool for each matching overdrive:<name> before its step: new work → intent-discovery; plan → decision-planning; tests → test-driven-development; build → risk-scaled-execution; parallel → parallel-execution; review → risk-scaled-review; bug → root-cause-debugging; decisions, copy → decision-log; corrections → compound-learning. User-only (read R/skills/<name>/SKILL.md): research → deep-research; PR, merge, deploy → release-gates; new skills → skill-evaluation.

If you were dispatched with a brief, follow the brief instead of this routing.
