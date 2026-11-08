---
type: regex
pattern: '^(?:[^\n]*\n){141}'
match: not_contains
target: {source: file, path: docs/plans/digest.md}
---
