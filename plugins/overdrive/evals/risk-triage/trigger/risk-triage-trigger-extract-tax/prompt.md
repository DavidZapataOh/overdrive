---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [risk-triage-trigger, validation]
---
src/orders/service.ts is getting messy, pull the tax calculation out into its own module (src/orders/tax.ts) and keep orderTotal behaving the same
