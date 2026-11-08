---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Skill]
tags: [root-cause-debugging-behavior, root-cause-debugging-smoke]
---
Use the root-cause-debugging skill. movingAverage in src/series.js returns one value too many: for [1, 2, 3, 4, 5] with window 3 it gives four averages and the last one is too low, which shows up as a dip at the end of the dashboard chart. Fix it.
