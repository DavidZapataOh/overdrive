# Eval results: deep-research (smoke)

Smoke numbers only: one run per case, with-skill arm, no baseline arm. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh deep-research --tier full --model main`), which has not run.

- Date: 2026-11-08 (UTC)
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5 (pressure: sonnet x5 and one `claude-opus-5-5` run per scenario)
- Judge model: none for smoke; the pressure compliance graders were read by hand
- Cost: about $17 in total (smoke batches $1.86 red, $4.36, $4.14, $3.98, keep-temp reruns about $3, pressure baselines and with-skill batches about $5)

## User-only skill

`disable-model-invocation: true`: the skill must never load on its own. The trigger set has ten near-miss negatives only (research as debugging, reports of test results, comparing functions, finding sources of a leak, lookups, Spanish "investiga", summarizing a paper, reviewing a PR); each passes when `Skill` is not called for it. Train 7/7, validation 3/3. `not-auto-invoked` (a natural "best Postgres host" question) requires an answer naming hosts and no `Skill` call. Both are negatives by nature, so they pass with or without the skill; the positive behavior is the slash-command cases.

## Red (skill absent)

Smoke with the skill directory removed: suite 0.84, 11/16. Behavior: every-claim-sourced 0.60, fans-out-independent 0.33, not-found-lists-attempts 0.67, patterns-vs-bets 0.25, unbiased-brief 0.60 (its neutrality graders pass vacuously with no agents; its positive graders fail), not-auto-invoked 1.00.

## Green (final skill)

Suite 1.00, 16/16 cases. Behavior: every-claim-sourced, fans-out-independent, not-found-lists-attempts, patterns-vs-bets, unbiased-brief and not-auto-invoked all 1.00.

Rounds that shaped the skill and graders:

- `every-claim-sourced` was 0.80 twice on `findings-all-sourced`: a `Gap:` line without a URL. The rule now says every Findings line, gaps included, ends with its URLs; then 4 of 4 reruns at 1.00. The grader is not loosened.
- `unbiased-brief` first failed `brief-written` because the model called the CLI through a shell variable; the grader now matches `brief ... --text` anywhere in the command.
- The report file made the Stop hook replace the final message with the Risk line, hiding the answer in pressure runs; the skill now says the last message gives the answer and the path first, the Risk line last.

Grader checks: no pattern matches text the prompt contains (trace patterns are confined to assistant text blocks, file patterns read the report); `unbiased-brief` also requires a researcher dispatch and a `brief --text` call, so a run with no agents fails; the report patterns need the report file to exist.

## Pressure scenarios (read by hand)

| Scenario | Without the skill | With the skill |
| --- | --- | --- |
| quick-yes-no-vendor | 5/5 compliant | 5/5 sonnet, 1/1 opus |
| one-search-then-not-found | 5/5 compliant | 5/5 sonnet, 1/1 opus |

Both baselines are compliant, so no rationalization table is written; the scenarios stay as regression checks. Details in `tests/pressure/deep-research/*/`.

## Known limits

- The brief's Rules section lists CLAUDE.md and the memory index, so a researcher can still read the project's name there. The neutral part is the question text the skill writes.
- The full tier (three runs per arm, both arms) has not run.
