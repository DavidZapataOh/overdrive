# Hypotheses and probes

## Contents

- The list
- Ranking
- One-variable probes
- Tagged output
- Secrets
- Three failed fixes

## The list

Write 3 to 5 hypotheses before the first probe, in this shape:

| # | Cause | If true, we will see | If false, we will see |
| --- | --- | --- | --- |
| 1 | the promo code is looked up case-sensitively | the lookup is `undefined` for `SAVE10` | the lookup succeeds for `SAVE10` |
| 2 | the cart arrives without `items` | `items` is missing in the logged body | `items` is present |

A hypothesis that no observation can rule out is rewritten until one can, or dropped.

## Ranking

Order by how well it explains every symptom in the report, not just the loudest one, then by how cheap it is to rule out. A cheap probe on the second hypothesis goes before an expensive one on the first. A theory handed over by someone else is a hypothesis with a rank, not a conclusion.

## One-variable probes

Each probe changes or observes one thing and states the expected result first. After a probe, update the table: the hypotheses it rules out are crossed out, the survivors reordered. When two probes disagree with the table, the table is wrong, not the probes.

## Tagged output

Temporary output looks like `console.error("[DEBUG-3fa9] key", key)`. The tag makes removal checkable with one search. It is written at the point where the value is produced or changes, not at the end where it is wrong. Every tagged line is removed before the regression test is committed.

## Secrets

Never print or paste tokens, passwords, API keys, full card or document numbers, or personal data into output, logs, commits or messages. Print a length, a prefix of four characters or a hash instead.

## Three failed fixes

After the third change that does not make the failing command pass, stop. Write for each: what it assumed, what the result showed. Then ask which assumption they share, which layer the evidence now points at, and whether the design (a shared mutable state, an interface that allows the invalid input) is what is producing the bug. Present that and ask before trying a fourth.
