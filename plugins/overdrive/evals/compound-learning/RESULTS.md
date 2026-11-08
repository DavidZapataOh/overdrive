# Eval results: compound-learning (smoke)

Smoke numbers plus the pressure, natural and behavior batches described below. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh compound-learning --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-08
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5 (opus 5.5 where stated)
- Judge model: claude-sonnet-5-5 (pressure and natural runs only; smoke uses free graders)

## Trigger set (1 run per case, 20 cases, max_turns 15)

Smoke after fix round 1, with the shortened description: train 15/15, validation 5/5 (only one positive, `idioma-otra-vez`, in validation, so that rate is weak evidence). Agent model claude-opus-5-5 (the smoke default). Before the skill existed the same pass scored train 7/15 and validation 4/5, but those positives fired the Skill tool on a skill that did not exist (the router text names it), so the red column measures the router, not the description.

## Behavior cases (3 runs, sonnet, max_turns 40; table from the first round, before the graders were tightened)

| Case | Without the skill (empty plugin) | With the skill |
| --- | --- | --- |
| correction-becomes-check | 0.50, 0.50, 0.50 | 1.00 x 3 |
| escaped-defect-calibrates-map | 0.33, 0.00, 0.33 | 1.00 x 3 |
| bar-fails-writes-nothing | 0.83, 0.66, 0.66 | 1.00 x 3 |
| no-empty-promise | 0.50, 0.75, 0.50 | 1.00 x 3 |

How to read the red column. The prompts say "Use the compound-learning skill", so `skill-loaded` (with-only) passes by instruction in the with arm and says nothing about natural loading. Without the skill, the failures on `check-written`, `fails-on-defect-copy`, `rule-persisted` and `rule-proved` are real behavior: the model removes the `console.log`, deletes the lockfile or edits the map and stops, with no check, no proof on a defect copy and no rule written. The red column for `says-why` was measured with a generic pattern (any phrase such as "one-off" or "nothing to record"); its failures were runs that gave no reason at all. The grader now requires the closing line `Learning: none — <why>`, which only the skill teaches, so without the skill that grader fails by construction: it checks the close format, and says nothing about behavior. The real behavior of that case (write nothing for a typo) already passes without the skill, so it is a guard against over-writing, not evidence of improvement. Scores for the red column were taken with the graders as first written; the with-arm and final numbers use the committed graders re-evaluated against the kept traces (the first draft of four graders was too narrow: it missed shell variables for the binary, heredoc writes and `path` instead of `file_path`; the text graders matched the skill's own text injected as a user message and were confined to assistant messages).

Smoke behavior after fix round 1 (1 run, claude-opus-5-5): the first pass scored bar-fails 0.83, correction-becomes-check 0.75, escaped-defect 0.75, no-empty-promise 1.00 and scope-as-stated 1.00. The escaped-defect miss was the grader (it did not read results whose `tool_use_id` comes before the type, nor a rule written and proved in one call); the correction miss was the run filtering its own pass/fail lines, which led to the skill text above; the bar-fails miss did not repeat. After the grader and text fixes: correction-becomes-check 1.00, escaped-defect 1.00, bar-fails 1.00 (single runs, not a rate).

## Pressure scenarios (hand-read, with the slash line)

| Scenario | Without (sonnet) | With the skill |
| --- | --- | --- |
| just-apologize | 0/5 compliant | sonnet 5/5 (judge 3/5), opus 1/1 |
| language-rule-again | 5/5 compliant (two prompt versions) | sonnet 5/5 (judge 3/5), opus 1/1 |

The judge numbers are lower because the Stop hook turns the last message into the Risk line, which the judge reads; the deterministic graders and the hand reading of the earlier text blocks agree on 5/5. language-rule-again does not break the baseline, so it justifies no rule and stays as a regression guard. just-apologize does: the control fixes the one named line, leaves the same slip in two other files and defers the check "after your presentation"; that justifies the "fix every copy", "a check is part of the fix" rules and the excuses table. The rest of the skill (the durable bar, the form ladder, the risk-map step and its note, scope, no promises, stop rules) is a design requirement, not justified by a baseline failure.

## Natural loading and end-to-end compliance (no slash command)

Five runs per scenario and model, shipping description, judge claude-sonnet-5-5. Details in `tests/pressure/compound-learning/<scenario>/natural.md`.

| Scenario | Opus loaded | Opus compliant | Sonnet loaded | Sonnet compliant |
| --- | --- | --- | --- | --- |
| language-rule-again | 5/5 | 5/5 | 4/5 | 4/5 |
| just-apologize | 3/5 | 4/5 | 0/5 | 2/5 |

Compliant counts the deterministic graders on the tool inputs; judge counts are in the scenario files (language-rule-again 5/5 and 4/5, just-apologize 4/5 and 1/5).

Known gap: just-apologize on sonnet loads the skill 0 of 5 and complies 2 of 5; on opus it loads 3 of 5. The user says "no process, no write-ups" and sonnet follows that without calling the Skill tool. `hooks/core.md` was not touched. Sonnet language-rule-again loads 4 of 5 (an earlier batch with the previous description loaded 5 of 5).

## Grader changes in fix round 1

- `fails-on-defect-copy` (all four graders): the failure marker must sit in the tool_result of the same Bash call whose command has the test command and a temp or copy path (`mktemp`, `/tmp/` outside the eval workspace, `$TMPDIR`, `cp`, `git worktree add`); `git stash` is not a copy. An earlier call on the real tree (no temp path) must show `fail 0`, after the check was written; one call that runs the real tree and then the copy is accepted if its output shows both. Results are bound by `tool_use_id` in the three key orders the trace uses.
- `check-written`: the path is anchored (`(^|/)tests?/`, `scripts/`, `.githooks/`, `.husky/`) and the written content must read files and hold the pattern in a regex literal or a match call (`console`, `toLocale` with `timeZone`, a Spanish accent class or common Spanish words).
- `rule-proved`: bound to the tool_result of the risk call (`lane critical` and `item money critical map`, so a floor does not count) plus a run on an unrelated path whose `Risk:` line has no money, in this call or another.
- `says-why` requires `Learning: none — `; `names-written-mechanism` is the positive companion of `no-empty-promise`; `rule-added` also accepts the other shapes of the skill's own table; the `*-fixed` graders accept a shared helper or constant; `comments-translated` and `pricing-translated` also catch unaccented Spanish.
- New: `note-written` (escaped-defect) and the `scope-as-stated` case (a repository-scoped convention must not be written under the user's home `.claude/`).
- The grader patterns were checked offline against 78 synthetic traces (each key order, parallel results, stash, filtered output) and against the kept real traces.

## Known gaps

- The full tier (three runs per arm, both models) has not run; every number here is smoke or a hand batch.
- Natural loading on just-apologize is below 4/5 on sonnet (above).
- The pressure graders changed in fix round 1 were checked offline only; the pressure batches were not rerun.
- A run that filters pass or fail lines out of its own output (for example `grep "^# fail"` when the reporter prints `ℹ fail`) is not credited; the skill now says to run the real tree and the copy as separate, unfiltered commands.
- `pressure.sh` keeps only the last message, which the Stop hook can turn into the Risk line; the judge and the kept final message lose the answer in those runs (tooling follow-up).
- The risk-map step cannot be run against a project corpus (`.overdrive/risk-cases/` is only written when the project already has it); no case covers that directory.
- The three-failed-attempts stop rule has no case; no run reached it.
- `scope-as-stated` covers one direction (repository convention stays out of the user's home); the reverse is not measured.

## Cost

Baselines about $1.2, red passes about $2.7, with-skill pressure about $2.0, natural about $9, behavior about $1.8, smoke passes about $6.7; about $24 in total.
