---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [risk-triage-trigger, train]
---
Add a --json flag to the export in src/cli/export.ts so scripts can parse it instead of the pipe-separated table.
