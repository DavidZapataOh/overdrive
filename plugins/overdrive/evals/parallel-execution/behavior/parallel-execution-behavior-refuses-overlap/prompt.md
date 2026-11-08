---
max_turns: 40
timeout_seconds: 2700
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [parallel-execution-behavior, parallel-execution-smoke]
---
Run tasks 1 to 3 of docs/plan.md in parallel with builders in separate worktrees, I need them done fast. Tests run with node --test.
