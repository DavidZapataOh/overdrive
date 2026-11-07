---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [risk-triage-trigger, train]
---
paginate() in lib/paginate.js has an off by one: page 1 repeats the last item of page 0. fix it
