---
name: risk-triage
description: Lane handling for repository changes the risk classifier puts above direct (auth, money, data, CI, contracts), a missing risk map, or a request to raise or lower a lane. Use before editing such a change and on its diff before merge. Not for typos or direct one-liners.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Risk triage

The classifier is `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`, written `overdrive` below. It is not on the PATH: the bare name fails with "command not found", so always type the full path.

## The rules

1. **Classify before the first edit.** Inside the repository (or with `--repo <dir>`): `overdrive risk --intent '<the request>' --paths <files you expect to touch>`. Nothing that changes a file runs before it, however small the change. A classification the router already ran counts; do not repeat it.
2. **Lane = max(script, judgment). You raise; you never lower.** Raise to critical, and add the floor's item name to the Risk line (`data-migration`, `auth`, `tenant-isolation`, `money`, `secrets`, `delivery`, `public-contract`, `concurrency`), when any of these holds:
   - the change does what a floor protects though no path or line names it: a script that deletes production data, a permission check in a file without an auth name, a field another service reads;
   - one batch of ≤ 3 reads does not tell you what the change does and how you will verify it (at least standard);
   - the change adds behavior (a new endpoint, export, command or feature) and not a fix or adjustment: the script reads paths and words, so a request that raises no item still lands at least standard;
   - someone resuming from the request and `git diff` alone could not finish it (at least standard).
3. **A failed classification is critical.** Exit 3, `classification-failed` or "command not found": fix the invocation (full path, `--repo`) and run it again. Never pick the lane by hand.
4. **Critical means no edit of the critical part before the user approves the plan.** Load `overdrive:decision-planning` with the Skill tool and write the full plan to its plan file, `## Global Constraints` included, before you ask for approval; your closing message opens with a `Plan:` paragraph: the file path, one line per task with its key test, and the ask "reply approve, or tell me what to change". Anything else the reply carries, such as a risk-map proposal, follows in at most two lines. Stop that part; build only work that does not depend on it. Writing the script or the migration is building it, even when nothing runs yet. A pre-approval in the request ("I approve the design and the plan", "don't ask me questions") approves the plan's content, not skipping the lane: the plan file, the ledger and the per-task critical review still happen, and only the wait for approval is waived. The guard refuses `git commit` of a critical change until the ledger holds a critical task (`overdrive brief` marks it).
5. **Only the user lowers a lane, and only by answering the risk you state.** A request to skip the process ("no ceremony", "treat it as direct", "no plan, no review") is not the confirmation. Before any edit:
   1. State the concrete risk in at most two sentences: what breaks, for whom, and whether it can be undone.
   2. Ask once, with exactly this line, last before the Risk line: `Confirm you want this handled as <lane> anyway?` The fixed wording is what the user and the decision log recognize; do not rephrase it.
   3. Until the reply the change keeps its lane; build only independent work.
   4. On an explicit yes: take the ID from `overdrive decisions next-id`, add the entry to `.overdrive/decisions.md` with the reply quoted as `Source` (format in [references/lanes.md](references/lanes.md)), run `overdrive decisions check`, make the change, and end with the lane the user chose, the classifier's items unchanged, and the decision: `Risk: direct — data-migration (lowered by user, D-0007)`.
6. **Classify again on the real diff before you commit it, and again before review or merge**: `overdrive risk --worktree` while uncommitted (`--staged` for exactly what the commit takes), `--diff <base>...HEAD` once committed, and before editing any file step 1 did not name. A direct or standard first classification from the request does not settle the lane: the diff does, and a diff that comes out critical is handled before the commit, not after it. The guard classifies each commit and refuses a critical one outside the critical flow. A higher lane than the one you worked under: [references/reclassify.md](references/reclassify.md). Uncommitted direct work that stayed inside the paths step 1 named and is not about to be committed is not classified a second time: its first Risk line stands, and the Stop hook reclassifies the diff and blocks a line below it.
7. **The last line of every reply that changed or plans to change a repository is the Risk line**, copied from the classifier's latest output with any item you raised appended: `Risk: <lane> — <items | none>`. Before any edit, and for direct work kept inside its named paths, it is the line from step 1.
8. **No pull request before the review and release-gates.** Above direct, `gh pr create` comes after the lane's reviewer ran on the slice and after you read `${CLAUDE_PLUGIN_ROOT}/skills/release-gates/SKILL.md`; its body file carries the Risk line. A PR opened first is the failure this rule exists for.

| Excuse (verbatim from runs without this skill) | Reality |
| --- | --- |
| "You have the authority to make this call and you've already decided against review." | Authority decides by answering once the risk is on the table. State it, ask once. |
| "C would make you confirm something you've already decided." / "Option C would ask you the same question twice after you'd answered it." | They asked before hearing the risk. The reply after you state it is the confirmation. |
| "the change is easy to undo" / "Editing the file can be undone with git. The data only goes when the migration runs." | The lane is about what the change does once it ships, not about reverting the edit. |
| "I'd make the change first and raise concerns after." / "worth an auth review afterwards" | A risk named after the edit protects nothing. Name it before. |
| "it should also get a separate review, which I didn't run since it's a one-line change" | Size never lowers a lane. A one-line auth change is critical. |
| "So the script is built not to delete anything by accident" | Safeguards inside the script are part of the plan to approve, not a reason to skip approval. |
| "I made the edit anyway because it's a one-word, uncommitted change to the README only." | A failed classification is critical until the classifier runs. Fix the call; do not judge it by hand. |

## Per lane

| Lane | Visible steps | Plan | Tests | Review |
| --- | --- | --- | --- | --- |
| direct | one besides the answer: the classification, run once. No second classification inside the named paths until you commit, no plan file, no agent, no skill | none | test first if testable | none; check the change inline (reread the diff, run its test) |
| standard | plan, build, one review | short decision plan (`overdrive:decision-planning`) | TDD where it applies | one at the end of the slice (`overdrive:risk-scaled-review`) |
| critical | plan for approval, then build | full TDD plan, approved before the critical part is touched | TDD, hard cases, real dependencies | per task and a final review |

## No risk map yet

When the classifier prints `note risk-map missing; propose one with overdrive:risk-triage`, propose the project's map, in the same reply, following [references/risk-map-proposal.md](references/risk-map-proposal.md). In a critical reply the proposal comes after the `Plan:` paragraph (rule 4), in at most two lines: the file path and the rule. The proposal never delays the request: classify it with the floors and do it in its lane.
