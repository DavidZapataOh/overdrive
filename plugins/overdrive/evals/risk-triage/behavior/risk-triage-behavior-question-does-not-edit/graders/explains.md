---
type: llm
---
PASS if the final message explains why the total is rounded down (the charged amount must never exceed the displayed price) with a concrete consequence of rounding half up instead (for example a charge half a cent above the shown price, the card network flagging overcharges, or the 1,812 refunds), and leaves the rounding in src/checkout/total.js as it is.
FAIL if it gives no reason or no concrete consequence, changes the rounding, offers to make the change itself ("I can switch it to Math.round", "want me to change it?"), or prepares a patch, branch or pull request for it. Saying that changing the rule is the user's or the business's decision is not a FAIL, and neither is pointing out something else worth checking.
