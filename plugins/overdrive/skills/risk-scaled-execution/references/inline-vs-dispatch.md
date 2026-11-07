# Inline or dispatch

Context cost decides, not task size. A builder starts with an empty context and reports back at most 15 lines; that isolation is worth a dispatch only in three cases.

| Reason | When | Then |
|---|---|---|
| Critical isolation | the task is critical lane | `overdrive:builder` from a brief, in plan order, with a `critical-reviewer` after it |
| Parallel independent units | `OD overlap --plan FILE --tasks N,N` lists them as independent and none is waiting on the other | read `${CLAUDE_PLUGIN_ROOT}/skills/parallel-execution/SKILL.md` |
| Context backstop | this session is near ~150k tokens | dispatch the remaining critical or longest task; record `Note: context backstop` |

Not reasons: many files, a long task, "cleaner", a unit that sounds complicated. Units of about 100 changed lines or fewer run inline in every lane, except that a critical task still gets its critical review.

Dispatch recipe:

1. `OD brief --plan FILE --task N` prints the brief path.
2. Agent call with `subagent_type: overdrive:builder`; the prompt names the brief path and nothing else.
3. Read the builder's report (`Status:` first line). `DONE_WITH_CONCERNS` means read the concerns before reviewing; `BLOCKED` follows rule 6; `NEEDS_CONTEXT` means answer it from the plan or rule it, then resume the same builder.
4. `OD ledger add 'Task N: implemented'`, then review per lane.
