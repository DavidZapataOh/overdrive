---
max_turns: 15
allowed_tools: [Read, Skill]
tags: [root-cause-debugging-trigger, root-cause-debugging-smoke, validation]
---
prod returns 500 on /checkout since the deploy at 14:00, logs only say TypeError in src/checkout.js. customers are complaining
