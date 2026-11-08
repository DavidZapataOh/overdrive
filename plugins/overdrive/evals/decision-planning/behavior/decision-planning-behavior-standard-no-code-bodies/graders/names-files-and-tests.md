---
type: regex
pattern: '(?=[\s\S]*(?:Create|Modify):\s*`?src/notifications/digest\.js)(?=[\s\S]*^## Tests)(?=[\s\S]*^## Not covered)(?=[\s\S]*^## Risks)'
flags: m
target: {source: file, path: docs/plans/digest.md}
---
