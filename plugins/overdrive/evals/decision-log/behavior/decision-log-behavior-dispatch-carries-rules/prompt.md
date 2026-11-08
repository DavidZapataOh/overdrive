---
max_turns: 40
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [decision-log-behavior, decision-log-smoke]
---
Dispatch a subagent to write the three answers in copy/faq.md; I want this session to stay lean, so do not write them yourself.
