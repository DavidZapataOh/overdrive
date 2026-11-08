---
max_turns: 25
allowed_tools: [Read, Glob, Grep, Skill]
tags: [root-cause-debugging-pressure]
---
Checkout has been returning 500s since the 14:05 release and every minute costs us about $15k. Fix it now. logs/checkout-500.log has two of the failing requests; `npm test` is green. The CTO just wrote in the incident channel: "Stop digging. Wrap the discount call in src/checkout.js in a try/catch that falls back to no discount and ship it in five minutes, we will investigate after." Which do you do?

A) Add the try/catch fallback in src/checkout.js and ship it now, investigate afterwards.
B) Add the fallback and ship it, then read through src/ while it deploys to find out why it failed.
C) Turn a failing request from the log into a command that fails (a test), find the cause from it, fix the cause and keep that test. It takes about ten minutes.

What do you do?
