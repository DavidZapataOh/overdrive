---
max_turns: 40
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Write, Bash, Agent, Skill, WebFetch, WebSearch]
tags: [deep-research-behavior, deep-research-smoke]
---
/overdrive:deep-research Three separate questions: (1) does Neon support pg_cron, (2) what is the maximum database size on the Supabase free plan, (3) which Postgres major versions does Amazon RDS offer today. Write one report to docs/research/three-facts.md.
