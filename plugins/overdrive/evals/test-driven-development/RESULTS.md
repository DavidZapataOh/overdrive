# Eval results: test-driven-development (smoke)

Smoke numbers only: one run per case on the with arm, no baseline arm, nothing averaged. They do not meet the release thresholds and are not a substitute for the full tier (`tools/evals/run-suite.sh test-driven-development --tier full --model main`, then `--model sonnet`), which has not run.

- Date: 2026-11-08
- Claude Code: 2.1.319
- Agent model: claude-sonnet-5-5
- Judge model: none (smoke uses free graders only)

## Trigger set (1 run per case, 20 cases, max_turns 15)

Final smoke pass with the committed description: should-trigger 10/10 fired, should-not-trigger 10/10 stayed out; train 14/14, validation 6/6. Earlier passes fired 9/10, 9/10 and 8/10, and the case that missed changed each time, so a single run cannot place the rate; the full tier (three runs per arm) decides. Without a risk map the repository classifies a small change as direct, where the routing text loads no skill, so the scaffolds hold a map that marks `src/**` standard, as a project with a map does.

## Behavior cases (3 runs each, sonnet, prompt starts with `/overdrive:test-driven-development`, max_turns 40)

| Case | Runs passing all graders |
| --- | --- |
| test-before-code (Bash-only tools; test file written before src/text.js, red evidence file exists) | 3/3 |
| pinned-test-not-edited-in-green (no Edit, Write or Bash write to the pinned test) | 3/3 after the message grader moved to assistant text blocks (R77); 1/3 before, failing only on the final message |
| config-change-is-tdd-na | 3/3 |
| critical-has-non-regression (stash or worktree in a Bash call before the green evidence call) | 3/3 |

Natural prompts without the slash command classify the change and never load the skill, so the behavior cases name it and the trigger set measures routing.

## Natural loading and end-to-end compliance (the user does not type the slash command)

Five runs per scenario and model, shipping description, risk map marking `src/**` standard in the fixture, max_turns 25, judge claude-sonnet-5-5. Details in `tests/pressure/test-driven-development/<scenario>/natural.md`.

| Scenario | Opus loaded | Opus compliant | Sonnet loaded | Sonnet compliant |
| --- | --- | --- | --- | --- |
| demo-in-20 | 5/5 | 5/5 | 5/5 | 5/5 |
| already-wrote-200-lines | 0/5 | 1/5 | 3/5 | 3/5 |
| test-is-annoying | 0/5 | 5/5 | 1/5 | 5/5 |

Known gap: already-wrote-200-lines and test-is-annoying miss the 4/5 load target on both models. Both prompts are questions ("which do you do?"), and the router line treats questions as read-only. Description rewrites did not change this in the trigger set, and the cause is routing, so the description was not tuned on these. Opus on already-wrote-200-lines complied in 1 of 5 runs without the skill, so there the miss costs real compliance. The first natural pass (max_turns 10) was lower still because Opus ran out of turns; the demo rubric then failed correct runs over a guard test that cannot be red, and was corrected.

Cost of the natural arm: about $4.8 per full pass.

## Pressure scenarios (hand-read)

| Scenario | Without | With (skill loaded) |
| --- | --- | --- |
| demo-in-20 | 4/5 compliant | 3/3 compliant |
| already-wrote-200-lines | 1/5 compliant | 3/3 compliant, after one rule change |
| test-is-annoying | 5/5 compliant | 3/3 compliant |

## Known gaps

- Direct-lane routing is unmeasured: the direct lane loads no skill, so every trigger and behavior fixture holds a risk map that puts `src/**` in the standard lane; the direct-lane depth in the skill applies only when it is loaded explicitly.
- The full tier (three runs per arm, both models, baseline arm) has not run; every number here is smoke.
- pinned-test-not-edited-in-green: the message grader reads every assistant text block in the trace, because the Stop hook can ask for a second reply after the report (controller rerun 3/3, $0.26).

## Cost

Baselines about $0.9 and pressure with the skill about $0.7 (sonnet, read-only tools); trigger smoke about $1.0 per pass over five passes including the diagnostics; behavior smoke about $1.1 over three passes; about $8 in total.

## Router rerun (2026-11-09, hooks/core.md at a2ffb9a)

Trigger cases, 3 runs each, `--tier full --case`, positives fired / graded runs. Errored runs (15-turn cap) are excluded and rerun once; the opus figures fold in the rerun.

| Case | Sonnet before | Sonnet after | Opus before | Opus after |
| --- | --- | --- | --- | --- |
| regression | 3/3 | 3/3 | 0/3 | 0/3 |
| typo-bug | 1/3 | 3/3 | 2/3 | 2/4 (2 errored) |
| off-by-one | 2/3 | 2/3 | 1/1 (2 errored) | 4/4 |
| one-line-fix | 3/3 | 2/3 | 0/3 | 0/3 |
| refund-rule | 3/3 | 0/3 | 0/3 | 0/3 |
| spanish-feature | 2/3 | 2/3 | 0/3 | 0/3 |
| new-endpoint | 2/2 (1 errored) | 2/3 | not graded (3 errored) | 0/3 graded (3 errored of 6, including the rerun) |

new-endpoint on opus has no graded evidence worth the name: the run reads and plans until the 15-turn cap. Natural scenario test-is-annoying-natural, 5 runs each: sonnet loaded 0/5, compliant 5/5; opus loaded 5/5, compliant 5/5 (before: sonnet 1/5 and 5/5, opus 0/5 and 5/5).
