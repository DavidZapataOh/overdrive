---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Bash, Edit, Write]
tags: [risk-triage-trigger, validation]
---
We need an archived_at timestamp on the projects table so we can hide old projects without deleting them. Add the migration.
