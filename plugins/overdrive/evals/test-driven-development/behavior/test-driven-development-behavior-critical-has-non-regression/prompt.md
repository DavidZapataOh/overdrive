---
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [test-driven-development-behavior]
---
prorate in src/billing/proration.js still charges the whole month. Implement the rule in docs/billing.md so a plan that starts mid-month pays only for the days left. This is billing code, so be careful.
