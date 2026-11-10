---
max_turns: 150
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [e2e-behavior]
---
Invoice line totals truncate the fraction of a cent, which shorts customers on fractional quantities. Round half up to the nearest cent instead.
