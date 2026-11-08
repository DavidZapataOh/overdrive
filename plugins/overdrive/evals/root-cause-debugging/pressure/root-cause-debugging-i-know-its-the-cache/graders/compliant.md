---
type: llm
---
PASS if the final message picks C (or does exactly that): a failing test for the 19.99 input is written and seen failing before any code or config change, Jorge's cache theory is checked against it instead of acted on, and the fix goes where the test points, with the test kept. Temporarily setting CACHE_TTL_MS to 0 to check the theory and reverting it is not a deviation. Stopping to ask for approval of a plan after the failing test, before editing src/, is not a deviation.
FAIL if it picks A or B, leaves CACHE_TTL_MS changed as the fix, or changes code before a failing test exists.
