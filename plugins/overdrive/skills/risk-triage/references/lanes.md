# Lanes in practice

## Contents

- Plan for approval (critical)
- Lowering: the question and the decision entry
- Judgment raises

## Plan for approval (critical)

A critical change waits for the user's approval of its plan before the files its critical items name are touched. The plan is in the reply itself, sized to the change; a one-constant change gets a five-line plan, not a document.

```
Plan for approval (critical: <items>)
1. Tests first: <the failing tests, by behavior: the case that must change and the cases that must not>
2. Change: <files and what changes in each>
3. Verify: <the commands, and the evidence they produce>
4. Review: per-task critical review, then the final review
Risk if it goes wrong: <one sentence: what breaks, for whom, whether it can be undone>

Approve this plan?

Risk: critical — <items>
```

While the plan waits, build what does not depend on it (an unrelated fix in the same request, reading, a test harness the plan needs) and say what was built. Nothing in the plan's step 2 happens before the approval arrives in a later message.

## Lowering: the question and the decision entry

The user asks to treat a change below its lane. Reply with the risk and the question, change nothing in its scope, and stop there:

```
<What breaks, for whom, whether it can be undone: at most two sentences.>
Confirm you want this handled as <lane> anyway?

Risk: <the classifier's lane> — <items>
```

Ask once. On an explicit yes in the user's next message:

1. `overdrive decisions next-id` gives the ID.
2. Append the entry to `.overdrive/decisions.md` (create the file with its two header lines if it does not exist):

   ```
   # Decisions
   Rules live in: CLAUDE.md files and the project memory index. This file holds rulings only.

   ## D-0007 — Handle the legacy_email drop as direct
   - Date: 2026-11-07
   - Scope: db/migrations/0007_cleanup.sql, the DROP COLUMN of users.legacy_email
   - Decision: Handle this change as direct instead of critical.
   - Source: "yes, handle it as direct" — user, 2026-11-07
   - Why: <the user's reason, in their words where they gave one>
   - Cost if wrong: <the risk you stated>
   - Status: active
   ```

   `Source` quotes the user's confirming reply verbatim; the Stop hook accepts a new decision only when its quote is attributed to someone other than the agent.
3. `overdrive decisions check` passes.
4. Make the change, classify it again, and end with the lowered line, keeping the items: `Risk: direct — data-migration (lowered by user, D-0007)`.

A "no", a counter-question or silence keeps the lane. The decision covers its scope only; the next change on the same files is classified from scratch.

## Judgment raises

The classifier reads paths, lines and the request; it cannot read what code means. Raise when the change does what a floor protects though nothing names it:

| Change | Raise to | Item |
| --- | --- | --- |
| A one-off script that deletes, purges or rewrites production data | critical | `data-migration` |
| A permission or ownership check in a file whose name says nothing about auth | critical | `auth` |
| A query that drops or widens a per-customer filter (`company_id`, `org_id`) | critical | `tenant-isolation` |
| A field, endpoint or event another service or customer consumes | critical | `public-contract` |
| Price, discount, rounding or currency arithmetic outside a billing path | critical | `money` |
| Shared state touched from parallel jobs, retries or webhooks | critical | `concurrency` |
| Not understood after one batch of ≤ 3 reads, or not resumable from the request and `git diff` | standard at least | none |

Write the raised item into the Risk line after the classifier's items: `Risk: critical — data-migration`. When the floors and the project map keep missing the same kind of change, the narrowest rule that would catch it belongs in `.overdrive/risk-map.conf` (a critical change of its own).
