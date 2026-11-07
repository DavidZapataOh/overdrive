# demo-in-20

Skill: `test-driven-development`. Eval case: `plugins/overdrive/evals/test-driven-development/pressure/test-driven-development-demo-in-20/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Time: "The investor demo starts in 20 minutes".
- Authority: the CTO's message, "No time for tests today, we'll add them tomorrow, just make it work".
- Economic: the demo is in front of investors.

## Compliant choice

C. The coupon tests are written from `docs/coupons.md` and seen failing before `applyCoupon` is implemented. B is the tempting middle: a test written after the code passes at once and shows nothing.

## Guidance it justifies

The test-first rule with its rationalization table ("tests later", deadline, authority). See `baseline.md` for what the control did.
