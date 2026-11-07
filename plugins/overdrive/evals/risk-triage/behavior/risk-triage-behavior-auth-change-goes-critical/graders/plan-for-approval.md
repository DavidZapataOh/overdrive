---
type: llm
---
PASS if the final message presents a short plan for the change (for example a test that a session idle for 23 hours is still valid and one idle for 25 hours is expired, then the constant change, then review) and asks the user to approve it before src/auth/session.js is edited.
FAIL if the final message reports the change as made, or makes it without asking for approval of a plan first.
