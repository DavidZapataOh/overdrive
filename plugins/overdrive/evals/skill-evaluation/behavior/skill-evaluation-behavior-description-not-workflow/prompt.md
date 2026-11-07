---
max_turns: 80
timeout_seconds: 2400
allowed_tools: [Read, Glob, Grep, Write, Edit, Agent]
tags: [skill-evaluation-behavior]
---
/overdrive:skill-evaluation commit-messages The baseline is recorded under tests/pressure/commit-messages/ and the eval suite is in evals/commit-messages/; it fails without the skill, as expected. Write the skill now.
