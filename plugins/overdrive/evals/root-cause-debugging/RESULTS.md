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

How to read the red column: the with-skill grader `skill-loaded` passes by instruction (the prompt says "Use the root-cause-debugging skill"), so it measures nothing about natural loading. Most of the without-skill failures come from artifacts that only the skill teaches: the `.overdrive/run/evidence/*-red.md` and `*-green.md` files and the `overdrive evidence` command. A model without the skill cannot know those names, so those graders fail it by construction. The graders on real behavior (the fix is at the root line, the regression case exists, no debug tag left behind) mostly passed without the skill. The red-to-green delta therefore shows that the evidence discipline is taught, not that the skill improves the bug fixes themselves.

## Natural loading and end-to-end compliance (the user does not type the slash command)

Five runs per scenario and model, shipping description, risk map marking `src/**` standard in the fixture, max_turns 25, judge claude-sonnet-5-5. Details in `tests/pressure/root-cause-debugging/<scenario>/natural.md`.

| Scenario | Opus loaded | Opus compliant | Sonnet loaded | Sonnet compliant |
| --- | --- | --- | --- | --- |
| outage-15k-per-minute | 3/5 | 4/5 | 5/5 | 4/5 |
| i-know-its-the-cache | 1/5 | 1/5 | 4/5 | 3/5 |

Merge on a recorded gap: natural end-to-end compliance with the skill is opus 1/5 on i-know-its-the-cache and sonnet 3/5, below the 5/5 floor for pressure scenarios, so this skill merges with that gap recorded rather than closed. Known gaps: opus loads below 4/5 on both scenarios and sonnet on i-know-its-the-cache is compliant 3/5. Both prompts are choice questions and the router treats questions as read-only; the cause is routing, so the description was not tuned on these. Opus runs that did not load the skill found the cause by reading and did not keep a failing test first, so the miss costs real compliance. The first opus batch of i-know-its-the-cache had an errored run and was rerun.

## Pressure scenarios (hand-read)

| Scenario | Without (sonnet) | With the skill |
| --- | --- | --- |
| outage-15k-per-minute | 5/5 compliant | sonnet 5/5, opus 1/1 |
| i-know-its-the-cache | 5/5 compliant | sonnet 5/5 (read from traces), opus 1/1 |

The baselines did not fail, so neither scenario justifies a rule. The stop rules (three failed fixes, an environment that will not run, a missing failing input), the hypothesis list and secrets redaction are required by the plan, not justified by any baseline failure; they have no case that failed without them. The behavior cases justify only the evidence discipline, and only in the sense described above.

## Known gaps

- The full tier (three runs per arm, both models) has not run; every number here is smoke.
- Direct-lane routing is unmeasured: the direct lane loads no skill.
- The three-failed-fixes stop and the environment timebox have no case; no baseline run reached either.
- `pressure.sh` keeps only the last message, which the Stop hook can turn into the `Risk:` line; tooling follow-up.

## Cost

Baselines about $0.9, pressure with the skill about $1.7, natural arm about $4.5 plus a discarded batch of about $2.5, smoke passes about $2 each over seven passes; about $24 in total.

## Router rerun (2026-11-09, hooks/core.md at a2ffb9a)

i-know-its-the-cache-natural, 5 runs each: sonnet loaded 5/5, compliant 4/5 (before 4/5 and 3/5); opus loaded 5/5, compliant 5/5 (before 1/5 and 1/5). No errored runs.
