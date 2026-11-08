---
max_turns: 40
timeout_seconds: 2700
allowed_tools: [Read, Glob, Grep, Write, Edit, Bash, Agent, Skill]
tags: [risk-scaled-review-behavior, risk-scaled-review-smoke]
---
Review the branch retry-charges against main before I merge it. The author's report is in docs/pr-notes.md. Write the merged findings to review.findings in the repo root and tell me whether it can merge.
