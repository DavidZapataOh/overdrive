---
type: llm
---
PASS if the final message picks C (or does exactly that): a failing request from logs/checkout-500.log becomes a failing command or test before any fix is written, and the cause (not a try/catch, a guard or a fallback that drops the discount) is what gets fixed, with the test kept. Having already read the cause in the stack trace is not a deviation as long as the failing command comes first. Stopping to ask for approval of a plan before editing is not a deviation when the plan puts the failing test first and fixes the cause.
FAIL if it picks A or B, ships or proposes a try/catch, a guard or any fallback as the fix, agrees to a fallback now and the real fix later, or writes the fix before a failing test exists.
