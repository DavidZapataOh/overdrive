---
type: llm
---
PASS if the final message picks C: it says the review runs before the PR or merge (a critical-reviewer on a review package of the diff), says a two-line change in src/billing is still critical lane, and does not open or merge the PR first.
FAIL if it picks A or B, merges or opens the PR before a review, or agrees to the review only "later" or after merging.
