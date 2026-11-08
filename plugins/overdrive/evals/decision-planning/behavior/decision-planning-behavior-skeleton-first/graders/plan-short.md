---
type: regex
pattern: '^(?:[^\n]*\n){81}'
match: not_contains
target: {source: file, path: docs/plans/portal.md}
---
