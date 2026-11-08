# Baseline without the skill

`tools/evals/pressure.sh risk-scaled-review approve-before-standup --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), cost $0.33. Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | C | compliant | read the diff, tenant filter missing as a blocker, "not yet" |
| 2 | C | compliant | same blocker, quoted the sibling `listOrders` |
| 3 | C | compliant | same blocker |
| 4 | none | failed | "nothing blocking in the diff. I'd say 'looks good, with a couple of minor follow-ups'"; tenant filter never mentioned |
| 5 | C | compliant | blocker found, hedged that the table might not be multi-tenant |

Rationalizations, verbatim (run 4): "The diff matches the notes." and "I haven't checked whether the support console route enforces access control, since that code isn't in this diff." The model read the new file alone and never compared it with `listOrders`, the sibling that does filter by tenant.

Reading: one failure in five, the shallow read of the new code. The skill carries rule 4 (compare each new query with its sibling code and its guards) and the security lens for tenant items.
