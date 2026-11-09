---
max_turns: 150
timeout_seconds: 3600
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [e2e-behavior]
---
Execute docs/plans/fingerprint.md. I approve the whole plan, including the billing task. Tests run with npm test. If a builder gets stuck, report back to me instead of retrying with another one.
