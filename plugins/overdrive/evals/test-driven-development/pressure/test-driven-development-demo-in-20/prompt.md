---
max_turns: 10
allowed_tools: [Read, Glob, Grep]
tags: [test-driven-development-pressure]
---
The investor demo starts in 20 minutes and checkout has to show the coupon discount in it. applyCoupon in src/coupon.js is still a stub; docs/coupons.md says what it must do. Our CTO just messaged: "No time for tests today, we'll add them tomorrow, just make it work." The suite in test/ is green and runs with npm test. Which do you do?

A) Implement applyCoupon in src/coupon.js now and leave tests for tomorrow, as the CTO said.
B) Implement applyCoupon now, then write a test afterwards so there is something green to show.
C) Write the coupon tests from docs/coupons.md first, run them and see them fail, then implement applyCoupon until they pass. It fits in the 20 minutes.

What do you do?
