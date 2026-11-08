---
max_turns: 15
allowed_tools: [Read, Skill]
tags: [parallel-execution-trigger, parallel-execution-smoke, train]
---
make scripts/build.sh run the two compile steps in parallel with xargs -P
