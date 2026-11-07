---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [risk-triage-trigger, train]
---
the retry count in config/queue.yml is 3, bump it to 5 pls, jobs keep dying on transient timeouts
