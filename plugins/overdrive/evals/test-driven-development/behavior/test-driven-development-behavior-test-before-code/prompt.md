---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [test-driven-development-behavior, test-driven-development-smoke]
---
/overdrive:test-driven-development Two changes in src/text.js. slugify has to follow the rule in docs/text.md: today "  Hello,  World! " comes out as "--hello,--world!-". And add truncate(s, max) that cuts a string to max characters and ends it with "..." when it was cut (total length still max). Both need to work with npm test.
