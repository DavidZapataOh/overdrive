# Model policy

Which model and effort each Overdrive agent runs on, and the measurements behind it. Every agent sets `model` and `effort` in its frontmatter; nothing sets `CLAUDE_CODE_SUBAGENT_MODEL*`.

## Standing rules

- Builders and the standard reviewer and researcher run on `sonnet`.
- The critical-lane reviewer and the final reviewer run on `opus`. A run on real tasks with them on `sonnet` let a production-only check go unrun through three reviews; the critical lane saves its cost by building in the main session and by one review and one correction, never by a cheaper reviewer.
- An effort setting changes only when the cheaper one is non-inferior on defects caught and measurably cheaper.
- A skill that fails pressure tests or evals on `sonnet` after the fix cap is re-dispatched on `opus` with the reason recorded; that is a one-off, not a policy change.
- Agents never poll CI. The controller watches it in the background and hands a fix agent the failing log excerpt.

## Current settings

| Agent | Model | Effort | Decision from the sweep |
| --- | --- | --- | --- |
| builder | sonnet | high | keep: medium saved nothing measurable |
| reviewer | sonnet | high | keep: opus caught the same defects for about 1.7 times the cost |
| critical-reviewer | opus | high | keep: xhigh caught the same defects for about 1.2 to 1.6 times the cost |
| final-reviewer | opus | xhigh | only for slices with two or more critical tasks |
| researcher | sonnet | medium | not swept |

## Sweep (Claude Code 2.1.321, main session `claude-sonnet-5-5`, with-plugin arm only, 5 runs per cell)

Overrides were temporary copies of the plugin outside the repository with only the agent frontmatter changed. Per-run figures are means. Cost is the whole session (main session plus every subagent), so it includes the parts that did not change between arms. Tokens are output tokens by model from the result's `modelUsage`; cache reads were within 10 percent between arms in every pair.

The two review cases of the `e2e` suite both classify as critical (tenant isolation, money), so they dispatch `critical-reviewer` and never the standard `reviewer`; the `e2e-standard-feature` case dispatches no builder (the standard lane builds inline) and its code has no defect to catch. Each agent was therefore paired with a case that exercises it:

| Agent | Case | What counts as a defect caught |
| --- | --- | --- |
| builder | single critical task from a plan (builder, then critical review) | tests written and green, `refundFee` correct (half up, 10 cent floor) |
| reviewer | `e2e-standard-feature` (clean code), plus a standard-lane branch with two seeded defects (1-based page treated as 0-based; page size cap claimed but missing) | both defects reported as P0 to P2 at confidence 50 or more |
| critical-reviewer | `catches-tenant-leak`, `rationale-does-not-downgrade`, plus a branch with two subtle seeded defects (cache keyed without tenant; check-then-refund race) | the seeded finding at P0 or P1 |

### builder: sonnet high vs sonnet medium

| Setting | Runs | Pass | Builder tokens (total) | Builder time | Session time | Session cost |
| --- | --- | --- | --- | --- | --- | --- |
| high | 5 | 5 of 5 | 25.0k | 43 s | 147 s | $0.45 |
| medium | 5 | 5 of 5 | 23.5k | 33 s | 181 s | $0.56 |

Both settings produced a correct `refundFee` and tests in every run I could read (the regexp grader for the floor was a style check and failed on named constants in 3 high runs, so it is excluded). Medium used 6 percent fewer builder tokens, but the session cost rose, driven by opus review output that varied by run (one medium run also dispatched a final review). Savings were not demonstrated, and one single-task case is thin evidence for lowering the effort of the agent that writes the code. Decision: keep high.

### reviewer: sonnet vs opus

| Case | Model | Runs | Defects caught | Pass | Reviewer-side output tokens | Time | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| seeded standard review | sonnet | 5 | 10 of 10 | 5 of 5 | 5.4k sonnet | 59 s | $0.20 |
| seeded standard review | opus | 5 | 10 of 10 | 5 of 5 | 4.8k opus, 2.6k sonnet | 71 s | $0.34 |
| e2e-standard-feature | sonnet | 5 | n/a (clean code) | 4 of 5 | 8.1k sonnet | 98 s | $0.26 |
| e2e-standard-feature | opus | 5 | n/a (clean code) | 5 of 5 | 3.6k opus, 4.8k sonnet | 97 s | $0.34 |

The one sonnet miss was a missing `evidence green` file written by the main session, not a reviewer verdict, so it does not argue for a stronger reviewer (see follow-ups). Decision: keep sonnet.

### critical-reviewer: opus high vs opus xhigh

| Case | Effort | Runs | Defects caught | Pass | Opus output tokens | Time | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| catches-tenant-leak | high | 5 | 5 of 5 | 5 of 5 | 6.9k | 69 s | $0.46 |
| catches-tenant-leak | xhigh | 5 | 5 of 5 | 5 of 5 | 16.5k | 104 s | $0.75 |
| rationale-does-not-downgrade | high | 5 | 5 of 5 | 5 of 5 | 5.7k | 67 s | $0.39 |
| rationale-does-not-downgrade | xhigh | 5 | 5 of 5 | 4 of 5 | 13.2k | 107 s | $0.59 |
| two subtle seeded defects | high | 5 | 10 of 10 | 5 of 5 | 10.7k | 84 s | $0.61 |
| two subtle seeded defects | xhigh | 5 | 10 of 10 | 5 of 5 | 24.2k | 132 s | $0.97 |

xhigh found nothing more and spent 2.2 to 2.4 times the opus output tokens. Its one failed run reported the right finding but wrote a malformed line in `review.findings`. Decision: keep high. These cases are saturated for both settings, so the data shows xhigh is not needed for these defect classes, not that it never helps; the final reviewer keeps xhigh because it reads the whole slice.

## Not covered

- The sweep above predates building critical tasks in the main session; `e2e-critical-after-approval` then ran two builder tasks, seven critical reviews and one final review (about $2 to $5 and 25 to 40 minutes a run). The builder now runs only for parallel tasks and the context backstop.
- The final reviewer and researcher settings were not swept.

## Follow-ups found by the sweep

- A standard-lane slice finished without an `evidence green` file in 1 of 5 sonnet runs of `e2e-standard-feature` (the arm with default agents). The reviewer ran; the evidence step was skipped by the main session.
- In 1 of 5 opus xhigh runs of `rationale-does-not-downgrade` the findings file contained a line outside the `F<n> | P<n> | <conf> | ...` format although the right finding was present; the run failed only on that format check.
