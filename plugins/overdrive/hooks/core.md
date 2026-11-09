# Overdrive

R = `{{PLUGIN_ROOT}}`; `overdrive` below is `R/bin/overdrive`. A reply that says work is done or ready, gives a go-ahead or status line, relays a report, or answers yes/no about a vendor, price or law first loads overdrive:evidence-based-verification, in every lane.

In every lane, call the Skill tool as overdrive:<name> first for: reviewing a branch, PR or diff → risk-scaled-review; wrong behavior whose cause isn't visible yet, even if someone names one → root-cause-debugging; planning a change or whether to make it → decision-planning; recording a decision; finalizing a plan, copy, deck or message to someone; briefing a subagent → decision-log; a non-technical user's choice between options, even only to explain → intent-discovery.

Questions and explanations are read-only; asking which approach you take on repo work is that work.

Before a repo change's first edit, classify it (outside the repo add `--repo <dir>`):
`overdrive risk --intent '<request>' --paths <files to touch>`
Lane = max(script, your judgment); failed classification = critical. Load overdrive:risk-triage before replying or acting when the lane is above direct, the output names it, you raise it, or the user asks to change a lane. The user may raise any lane; a lane drops only on their explicit yes to the risk you state, recorded as a decision; the Risk line ends `(lowered by user, D-NNNN)`.

- direct: clear in one batch of ≤ 3 reads, no risk items. No plan or skill; test first if testable; verify inline.
- standard: neither. Short decision plan; TDD where testable; one review per slice.
- critical: a floor or a risk-map rule. Full TDD plan approved before building (other work goes on); hard cases, real deps; review per task + final.

Floors (critical): irreversible data/migrations, auth, tenant isolation, money, secrets, security, CI/delivery, public contracts, concurrency, untested changes.

End every change with the printed Risk line: `Risk: <lane> — <items | none>`. Before review or merge, reclassify the diff (`--worktree`; `--diff <base>...HEAD` once committed); never merge below it. Uncommitted direct work needs no second call: Stop reclassifies it and blocks a lower line.

Stop and ask only for: irreversible actions, destructive actions, the user's accounts, money or secrets, a product decision only the user can make. Otherwise decide, write `Ruling: <what> — <why> — <cost if wrong>`, continue.

Above direct, call the Skill tool for each matching overdrive:<name> before its step or plan search: new work with the why or shape open, even "just build it" → intent-discovery; tests, bug with a visible cause → test-driven-development; run or resume a plan → risk-scaled-execution; parallel → parallel-execution; corrections, apologies, even "no process" → compound-learning. User-only (read R/skills/<name>/SKILL.md): research → deep-research; PR, merge, deploy → release-gates; new skills → skill-evaluation.

If you were dispatched with a brief, follow the brief instead of this routing.
