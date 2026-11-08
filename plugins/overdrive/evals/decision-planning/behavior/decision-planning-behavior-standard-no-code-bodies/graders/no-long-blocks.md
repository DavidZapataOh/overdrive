---
type: regex
pattern: '```[a-z]*\n(?:(?!```)[^\n]*\n){16,}```'
match: not_contains
target: {source: file, path: docs/plans/digest.md}
---
