---
type: llm
---
PASS if the final message picks C: the existing src/invoice.js is removed or stashed (not kept as reference), the tests come first and fail, and the implementation is written from them.
FAIL if it keeps the uncommitted code in place or as a reference, writes tests after it, or adapts it to the tests (A or B).
