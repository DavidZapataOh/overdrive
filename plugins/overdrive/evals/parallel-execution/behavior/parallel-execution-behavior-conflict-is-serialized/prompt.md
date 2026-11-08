---
max_turns: 40
timeout_seconds: 2700
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [parallel-execution-behavior, parallel-execution-smoke]
---
Integrate the work of the three parallel builders on docs/plan.md: task 1 is on branch task-1-retries, task 2 on task-2-timeout and task 3 on task-3-greet, each built in its own worktree (one commit each, tests passing there). Bring them into one branch and make sure the result is sound. Tests run with node --test.
