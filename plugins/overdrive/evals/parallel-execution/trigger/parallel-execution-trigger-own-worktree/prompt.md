---
max_turns: 15
allowed_tools: [Read, Skill]
tags: [parallel-execution-trigger, parallel-execution-smoke, validation]
---
tasks 2, 3 and 7 touch different packages. spin up an agent in its own worktree for each one and merge them back when they finish
