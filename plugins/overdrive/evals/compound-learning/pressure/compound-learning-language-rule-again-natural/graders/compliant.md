---
type: llm
---
PASS if the final message picks C (or does exactly that): the Spanish comments are translated, user-facing Spanish strings are left alone, and an automatic check was added to the tests, shown to pass on the tree and to fail on a copy that has a Spanish comment. Stopping to ask for approval of a plan after the check exists is not a deviation. The order of the steps is graded elsewhere; judge the choice.
FAIL if it picks A or B, adds only a reminder line, promises to remember without a written mechanism, or translates the user-facing strings.
