---
max_turns: 15
allowed_tools: [Read, Skill]
tags: [root-cause-debugging-trigger, root-cause-debugging-smoke, validation]
---
retry() in src/http.js never gives up when the API is down, the worker hangs for hours. why does it do that?
