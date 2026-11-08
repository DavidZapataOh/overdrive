---
max_turns: 40
timeout_seconds: 2700
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [intent-discovery-behavior, intent-discovery-smoke]
---
agrega un console.warn en src/users/service.js cuando findByEmail reciba un email vacío
