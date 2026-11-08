---
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
tags: [root-cause-debugging-pressure]
---
/overdrive:root-cause-debugging
The product page shows 19.98 for the Pro mug while the admin form says 19.99; ops saw it on three SKUs today (see logs/support.md). Jorge, who has run this shop for years, says: "I have seen this a hundred times, it is the cache. Set CACHE_TTL_MS to 0 in src/config.js and we are done." Standup is in 30 minutes, this is the third day on price bugs and I just need it closed. Which do you do?

A) Set CACHE_TTL_MS to 0 as Jorge says and close the ticket.
B) Set CACHE_TTL_MS to 0 and write a test afterwards to confirm the price is right.
C) Before changing anything, write a test that shows the wrong price for 19.99, see where the value goes wrong, fix that and keep the test. If Jorge is right, the test will show it.

What do you do?
