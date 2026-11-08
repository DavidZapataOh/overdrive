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

Smoke with the skill directory removed: suite 0.84, 11/16. Most of that red is not skill behavior: without the plugin there is no `/overdrive:deep-research` slash command, so the prompt is not understood as a command, and several graders look for format names that only the skill teaches (`N of M`, `Gap:`, `Bet:`, `- Tried:`, `Research:` lines). The red shows the suite can fail; it does not show that a capable model without the skill would do worse on substance. Behavior: every-claim-sourced 0.60, fans-out-independent 0.33, not-found-lists-attempts 0.67, patterns-vs-bets 0.25, unbiased-brief 0.60 (its neutrality graders pass vacuously with no agents; its positive graders fail), not-auto-invoked 1.00.

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

Both baselines are compliant (5/5), so they justify no SKILL.md text and no rationalization table is written; the scenarios stay as regression checks. What the skill states is mandated by the plan, not by a recorded failure: rules 4 to 7 (cap, status lines, `N of M`, `Gap:`/`Bet:` labels, report layout).

## Fix round 1

- Identity leak: `overdrive brief --text` lists CLAUDE.md, the memory index and recall lines and sits under the repository path, so it leaked the project to comparison researchers. For a comparison the skill now reads the rules itself and writes a neutral brief with Write outside the repository (`${TMPDIR:-/tmp}/overdrive-research/<n>.md`): task, cap, research rules as bare sentences, report contract; no paths, rules chain or project name. `brief --text` stays for non-comparison questions.
- `unbiased-brief` graders are case-insensitive and cover `acme-ranker`. A positive grader requires a Write under `overdrive-research/` that names the candidates and matches neither `acme[ -]?ranker` nor `CLAUDE.md`; a second one fails any such Write that does; others fail a shell brief, `brief --text`, or an Agent prompt that leaks. Falsified offline: a Write of a real `brief --text` file (CLAUDE.md path, repository path) fails the positive grader and the leak grader.
- Failed calls no longer count: the dispatch and brief counts are paired with result-side graders (report file exists, names the candidates and cites at least five URLs; fans-out: report names the three subjects with at least three URLs).
- Minor: `findings-all-sourced` accepts `-`, `*` and numbered bullets and path-like `file.ext:line`; `patterns-vs-bets` requires `- Gap:` and `- Bet:` lines inside Findings; `not-auto-invoked` names hosts only; `status-line` needs at least two milestone lines.

Smoke after the fix (sonnet, one pass of the six behavior cases and ten triggers): 15 of 16 cases at 1.00 and `unbiased-brief` 0.88, because the model wrote the briefs with a shell heredoc instead of Write; the skill now says "with the Write tool (not a shell command)". Rerun of `unbiased-brief` alone (3 runs): every grader passed in all 3 (neutral brief written, no leak in Write, shell or Agent prompt, report names the candidates and cites at least five URLs). The first grader draft required all candidates in one brief although each brief covers one; it failed 3 of 3 on real traces and was corrected, then checked offline against the 9 kept Write inputs. Cost of the fix round: first smoke $4.45, `unbiased-brief` reruns about $6 each (three runs per pass).

## Known limits

- Non-comparison questions still use `brief --text`, whose Rules section lists CLAUDE.md and the memory index; only comparisons are neutral.
- The full tier (three runs per arm, both arms) has not run.
