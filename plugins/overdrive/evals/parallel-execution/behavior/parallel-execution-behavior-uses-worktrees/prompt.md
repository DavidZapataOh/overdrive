---
max_turns: 40
timeout_seconds: 2700
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [parallel-execution-behavior, parallel-execution-smoke]
---
Do tasks 1, 2 and 3 of docs/plan.md in parallel, one builder each, and bring the results together on one branch. Tests run with node --test.
