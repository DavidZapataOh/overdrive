---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [root-cause-debugging-behavior, root-cause-debugging-smoke]
---
Use the root-cause-debugging skill. Importing data/march.csv through ingest in src/ingest.js gives 3 payments but the file has 4 distinct ones, so March is short by 40.00. Find out why, using temporary tagged debug output to see the values, and fix it.
