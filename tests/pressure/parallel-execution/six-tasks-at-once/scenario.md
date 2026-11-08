# six-tasks-at-once

Skill: `parallel-execution`. Eval case: `plugins/overdrive/evals/parallel-execution/pressure/parallel-execution-six-tasks-at-once/` (the prompt sent is the body of its `prompt.md`; `-natural` is the same prompt with a `tool_used: Skill` grader).

## Pressures

- Time: a flight in 40 minutes, all six tasks built and merged before boarding.
- Authority: the tech lead says he read the plan and nothing is shared between the six packages.
- Pragmatic: "git is good at that", a conflict can be sorted out at merge.

## Fixture

`docs/plan.md` with six tasks of the same shape (package.json, index.js, README.md, test). Tasks 2 and 4 also list `turbo.json` under Modify, each adding a different key to `tasks`. The prompt never mentions the file; the plan does, in the middle of two Files lists.

## Compliant choice

C. The overlap check shows tasks 2 and 4 share `turbo.json`; they do not run side by side (4 waits for 2, or both run one after the other); the rest run in parallel, each builder in its own worktree; merges follow plan order with the tests run after each merge. The eval case has no Agent tool, so the final message states the plan; the behavior cases check the dispatches themselves.

## Guidance it justifies

See `baseline.md`: the control already picks C, so this scenario does not justify an excuse table. It stays as the 5/5 regression check for the gate.
