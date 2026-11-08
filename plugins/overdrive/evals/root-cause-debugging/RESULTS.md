# Eval results: root-cause-debugging (smoke)

Smoke numbers only: one run per case on the with arm, no baseline arm, nothing averaged. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh root-cause-debugging --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-08
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5
- Judge model: none (smoke uses free graders only)

## Trigger set (1 run per case, 20 cases, max_turns 15)

Final smoke pass with the committed description: train 14/15, validation 4/5 (floor 90%: not met on this single run). The validation miss is `loops-forever`; it was not used to tune the description. Description edits used train misses only (`last-page`, `spanish-total`), two rounds; train misses move between passes (`last-page` fired in one pass and missed in the next), so one run cannot place the rate and the full tier decides. Without the skill (skill directory removed) the same suite scored 12/24 and the four behavior cases 0.60, 0.33, 0.00 and 0.67.

## Behavior cases (1 run, sonnet, max_turns 40)

| Case | Without the skill | With the skill |
| --- | --- | --- |
| repro-before-fix (red evidence file, then Edit on src/) | 0.00 | 1.00 |
| root-not-symptom (root line changed, no clamp/filter/pop) | 0.67 | 1.00 |
| regression-test-added (window-3 case in the suite, green evidence) | 0.33 | 1.00 |
| debug-logs-removed (no `[DEBUG-` in src, key fixed, red evidence) | 0.60 | 1.00 |

The prompts name the skill ("Use the root-cause-debugging skill") because the slash command does not register as a Skill call and the `skill-loaded` grader (with-only) needs one. Natural loading is measured below.

## Natural loading and end-to-end compliance (the user does not type the slash command)

Five runs per scenario and model, shipping description, risk map marking `src/**` standard in the fixture, max_turns 25, judge claude-sonnet-5-5. Details in `tests/pressure/root-cause-debugging/<scenario>/natural.md`.

| Scenario | Opus loaded | Opus compliant | Sonnet loaded | Sonnet compliant |
| --- | --- | --- | --- | --- |
| outage-15k-per-minute | 3/5 | 4/5 | 5/5 | 4/5 |
| i-know-its-the-cache | 1/5 | 1/5 | 4/5 | 3/5 |

Known gaps: opus loads below 4/5 on both scenarios and sonnet on i-know-its-the-cache is compliant 3/5. Both prompts are choice questions and the router treats questions as read-only; the cause is routing, so the description was not tuned on these. Opus runs that did not load the skill found the cause by reading and did not keep a failing test first, so the miss costs real compliance. The first opus batch of i-know-its-the-cache had an errored run and was rerun.

## Pressure scenarios (hand-read)

| Scenario | Without (sonnet) | With the skill |
| --- | --- | --- |
| outage-15k-per-minute | 5/5 compliant | sonnet 5/5, opus 1/1 |
| i-know-its-the-cache | 5/5 compliant | sonnet 5/5 (read from traces), opus 1/1 |

The baselines did not fail, so neither scenario justifies a rule; the skill is justified by the behavior cases above (no recorded red run, regression tests missing, symptom edits).

## Known gaps

- The full tier (three runs per arm, both models) has not run; every number here is smoke.
- Direct-lane routing is unmeasured: the direct lane loads no skill.
- The three-failed-fixes stop and the environment timebox have no case; no baseline run reached either.
- `pressure.sh` keeps only the last message, which the Stop hook can turn into the `Risk:` line; tooling follow-up.

## Cost

Baselines about $0.9, pressure with the skill about $1.7, natural arm about $4.5 plus a discarded batch of about $2.5, smoke passes about $2 each over seven passes; about $24 in total.
