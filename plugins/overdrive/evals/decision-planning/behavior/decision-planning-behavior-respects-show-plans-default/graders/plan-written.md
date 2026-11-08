---
type: regex
pattern: '(?=[\s\S]*^## Not covered)(?=[\s\S]*^### Task 1:)'
flags: m
target: {source: file, path: docs/plans/digest.md}
---
