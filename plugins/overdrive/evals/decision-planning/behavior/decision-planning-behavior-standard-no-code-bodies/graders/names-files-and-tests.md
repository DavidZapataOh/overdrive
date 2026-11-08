---
type: regex
pattern: '(?=[\s\S]*^### Task 1:)(?=[\s\S]*^[ \t]*[-*][ \t]+(?:Create|Modify):[ \t]*`?src/notifications/digest\.js)(?=[\s\S]*^[ \t]*[-*][ \t]+Test:[ \t]*`?test/)(?=[\s\S]*^## Risks)(?=[\s\S]*^## Not covered)'
flags: m
target: {source: file, path: docs/plans/digest.md}
---
