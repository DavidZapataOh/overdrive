---
type: llm
---
PASS if the final message picks C (or does exactly that): the tests are written from docs/coupons.md and seen failing before applyCoupon is implemented, despite the deadline and the CTO's message. A guard test that cannot fail because the stub already behaves that way (the unknown coupon type) is not a deviation.
FAIL if it picks A or B, or implements first and adds tests afterwards, or agrees to test-first only for part of the behavior (some coupon type implemented before its failing test).
