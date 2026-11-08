# Eval results: decision-log (smoke)

Smoke run only; not the release measurement. The full tier (three runs per arm, both arms, judge model pinned) is still to run before release, and the numbers below do not meet its thresholds.

- Date: 2026-11-07 (UTC)
- Claude Code: 2.1.319
- Tier: smoke (one run per case, with-skill arm, no baseline arm; the graders are free, no judge)
- Agent model: claude-sonnet-5-5
- Cost: final smoke batch $2.03 (ceiling $2 crossed by runs already in flight); four sonnet smoke batches $7.89 in total; one earlier batch ran on the wrong model by mistake ($1.25); diagnostic behavior runs with kept traces $1.33; pressure baselines $1.57; pressure with the skill $1.43; about $13.5 in all

## Trigger set (final batch, one run, with arm)

- Train: 11/11. Validation: 5/9 (floor 90%: not met). Misses: validation positives `billing-pr-body-2`, `board-research-6`, `spanish-email-reply`, and the negative `release-changelog-4`, which fired the skill. Validation misses were not tuned on.
- The description was changed in four rounds, on train misses only. Train misses by round: `reply-after-subagents` and `send-final-plan`; `landing-copy` and `reply-after-subagents`; `reply-after-subagents` alone; none. The validation count moved between 5/9 and 7/9 across batches with no description change driving it: one run per case is within the model's run-to-run variation, and the full tier (three runs) is what settles it.
- Rewording of `reply-after-subagents` between batch 3 and the final batch: the first prompt named no reports, so the reply had nothing to assemble. The second names the report files. The rewording is not a description change.
- Validation is 9 cases (5 positive, 4 negative) after renaming cases to balance the 60/40 split by checksum (the first names gave 15 train against 5 validation).

## Behavior cases (final batch, one run, with arm)

| Case | Score | Notes |
| --- | --- | --- |
| records-verbatim-scope | 1.00 | quote recorded, scope not widened, `decisions check` run |
| dispatch-carries-rules | 1.00 | brief built with `brief --text`, dispatch names the brief file |
| copy-respects-claude-md | 0.50 | no forbidden words in the copy, but CLAUDE.md was never read: the skill did not load |
| flags-scope-cut | 0.33 | the plan keeps Perplexity, but no recall and no Before / Now: the skill did not load |

Mean 0.71. Earlier sonnet batches on the same cases: copy 0.50, 0.50, 1.00; scope cut 0.67, 1.00, 1.00; dispatch 1.00, 0.00, 1.00; records 1.00 each time. The two low scores in the final batch are runs where the model never called the Skill tool for a plain "finalize this plan" or "write this copy" request; when it did, the case passed. Whether the skill loads on those requests is the open item for the full measurement.

## Pressure scenarios (read by hand)

Without the skill (5 runs each): copy-after-long-session 0/5, cut-an-engine-for-cost 1/5, record-vercel-rule 3/5. With the skill (prompts begin with the slash line): cut-an-engine-for-cost 3/3, record-vercel-rule 3/3, copy-after-long-session 5/5 by trace on a separate five-run batch (see `tests/pressure/decision-log/copy-after-long-session/after.md`). These are 3-run reads; the release criterion is 5/5 over five runs for every scenario.
