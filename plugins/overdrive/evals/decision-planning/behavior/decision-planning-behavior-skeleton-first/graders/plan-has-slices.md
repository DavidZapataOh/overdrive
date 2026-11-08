---
type: regex
pattern: '^## (Slices|Versions)\b[\s\S]*^## Not covered\b'
flags: m
target: {source: file, path: docs/plans/portal.md}
---
