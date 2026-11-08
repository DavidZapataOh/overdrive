# Eval results: decision-log (smoke)

Smoke run only; not the release measurement. The full tier (three runs per arm, both arms, judge model pinned) is still to run before release.

- Date: 2026-11-07 (UTC)
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, no baseline arm; free graders only, no judge)
- Agent model: claude-sonnet-5-5 (behavior cases once on claude-opus-5-5, see below)
- Cost, fix round 1: final sonnet smoke $1.96 (an earlier batch with the same graders $2.01); natural arm $1.35 sonnet and $2.69 opus; slash pressure after, 5 runs per scenario, $1.39; opus behavior $0.95 and $1.02; about $11.4. Round 0 cost about $13.5.
- Grading source: until the harness fix for dotfiles in the eval cwd merges, the Stop hook's risk reply replaces the final message in some runs, so graders read the trace (assistant text, tool calls and tool results) rather than the last message. Pressure and natural runs are read by hand from traces.

## Trigger set (final batch, one run, with arm)

- Train 10/10; validation 9/10 (floor 90%: met on this single run). Miss: positive `spanish-email-reply`. The set now has 10 positives and 10 near-miss negatives (decisions table in a schema, a typo in the landing copy, renaming `logDecision`, a failing `parseDecision` test, ADR question, Sentry logging, git log, changelog entry, explain code, decision tree), split 10/10 by checksum. The earlier batch with these cases gave train 10/10, validation 8/10 (also `release-changelog-4` fired).
- The description was trimmed of "Checks work against project rules and past decisions." No other change this round. One run per case is within run-to-run variation; the full tier settles it.

## Behavior cases (final batch, one run, with arm, sonnet)

| Case | Score | Notes |
| --- | --- | --- |
| records-verbatim-scope | 1.00 | quote recorded, Scope line names Vercel Pro only, log check passed after the append |
| dispatch-carries-rules | 1.00 | brief built before the dispatch, its path carried into the Agent prompt, FAQ answered |
| copy-respects-claude-md | 0.75 | rules read before writing and real copy, but the copy says "sin una sola reunión" (a negated forbidden word): the grader fails it with word boundaries, as asked |
| flags-scope-cut | 0.40 | skill loaded but no `recall` run, so no recall result; the plan itself is not cut |

Graders were rewritten so each fails on the wrong behavior (plan engines section lists all four with no cut note, Before and Now in assistant text, the real `recall` command plus its result, ordered brief then dispatch, ordered rules read then copy write, positive Scope check). The fixture where the engines section is a TODO means an untouched file fails.

### Opus, once (claude-opus-5-5)

copy-respects-claude-md 0.75 (negated "reunión" and "llamadas" in the copy), flags-scope-cut 1.00, records-verbatim-scope 1.00, dispatch-carries-rules passed brief-then-agent and brief-path-carried; its subagent left `TODO:` markers for facts the repo lacks, which the earlier FAQ grader rejected, so that grader now checks that the answers exist.

## Natural arm (no slash line, 5 runs per model, read from traces)

| Scenario | Sonnet loaded | Sonnet compliant | Opus loaded | Opus compliant |
| --- | --- | --- | --- | --- |
| copy-after-long-session | 4/5 | 4/5 | 4/5 | 5/5 |
| cut-an-engine-for-cost | 3/5 | 3/5 | 4/5 | 4/5 |
| record-vercel-rule | 5/5 | 5/5 | 5/5 | 5/5 |

Target 4/5 per model. Known gap: Sonnet on cut-an-engine-for-cost loads the skill in 3/5 and complies in 3/5 (no run cut the engine, but the runs without the skill omit the Before / Now / Why form). Routing for plans and final replies is a change to the session router, outside this skill. Details in `tests/pressure/decision-log/*/natural.md`.

## Pressure scenarios with the slash line (5 runs each, sonnet, read from traces)

copy-after-long-session 5/5, cut-an-engine-for-cost 5/5, record-vercel-rule 5/5. Without the skill: 0/5, 1/5, 3/5.
