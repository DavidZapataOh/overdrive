---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [compound-learning-behavior, compound-learning-smoke]
---
Use the compound-learning skill. Yesterday a double charge reached customers: the renewal retry in src/renewals/retry.js was changed, the change was classified standard, got a quick review and shipped. The code is already fixed in the last commit. A change like that has to be treated as critical from now on.
