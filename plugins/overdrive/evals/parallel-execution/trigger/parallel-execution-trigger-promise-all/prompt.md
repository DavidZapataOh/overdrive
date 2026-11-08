---
max_turns: 15
allowed_tools: [Read, Skill]
tags: [parallel-execution-trigger, parallel-execution-smoke, validation]
---
use Promise.all here so the three fetches in src/dashboard/load.ts happen at once
