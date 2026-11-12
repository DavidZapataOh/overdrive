# Inline or dispatch

Context cost decides, not task size or lane. A builder starts with an empty context, spends minutes reading before it writes and reports back at most 15 lines; that is worth paying in two cases only.

| Reason | When | Then |
|---|---|---|
| Parallel independent units | `OD overlap --plan FILE --tasks N,N` lists them as independent and none is waiting on the other | read `${CLAUDE_PLUGIN_ROOT}/skills/parallel-execution/SKILL.md` |
| Context backstop | this session is near ~150k tokens | dispatch the remaining longest task; record `Note: context backstop` |

Not reasons: the critical lane, many files, a long task, "cleaner", a unit that sounds complicated. A critical task is built here; its independence comes from the critical reviewer, who reads the diff with a fresh context and reruns the evidence.

Dispatch recipe (when a reason holds):

1. `OD brief --plan FILE --task N` prints the brief path.
2. Agent call with `subagent_type: overdrive:builder` and `Task N` in its description; the prompt names the brief path and nothing else. Wait for it in this turn.
3. Read the builder's report (`Status:` first line). `DONE_WITH_CONCERNS` means read the concerns before reviewing; `BLOCKED` follows rule 6; `NEEDS_CONTEXT` means answer it from the plan or rule it, then resume the same builder.
4. `OD ledger add 'Task N: implemented'`, then review per lane.
